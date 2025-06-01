const express = require('express');
const postService = require('../services/postService');
const router = express.Router();

// Middleware to verify that user is authenticated
const verifyToken = (req, res, next) => {
  const token = req.header('x-auth-token');
  
  if (!token) {
    return res.status(401).json({ message: 'No token, authorization denied' });
  }
  
  try {
    // User object is already set in the gateway
    next();
  } catch (error) {
    res.status(401).json({ message: 'Token is not valid' });
  }
};

// Create a post
router.post('/', verifyToken, async (req, res) => {
  try {
    const { content, imageUrl } = req.body;
    
    if (!content || content.trim() === '') {
      return res.status(400).json({ message: 'Content is required' });
    }
    
    const post = await postService.createPost(req.user.id, content, imageUrl);
    
    res.status(201).json(post);
  } catch (error) {
    console.error('Create post error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get a post by ID
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const post = await postService.getPostById(req.params.id);
    
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }
    
    // Check if the authenticated user has liked this post
    const hasLiked = await postService.hasLiked(req.user.id, req.params.id);
    
    res.json({
      ...post,
      hasLiked,
    });
  } catch (error) {
    console.error('Get post error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all posts by a user
router.get('/user/:userId', verifyToken, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    
    const posts = await postService.getPostsByUser(req.params.userId, page, limit);
    
    // For each post, check if the authenticated user has liked it
    const postsWithLikeStatus = await Promise.all(
      posts.map(async (post) => {
        const hasLiked = await postService.hasLiked(req.user.id, post.id);
        return {
          ...post,
          hasLiked,
        };
      })
    );
    
    res.json(postsWithLikeStatus);
  } catch (error) {
    console.error('Get user posts error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Like a post
router.post('/:id/like', verifyToken, async (req, res) => {
  try {
    const result = await postService.likePost(req.user.id, req.params.id);
    
    if (result.error) {
      return res.status(400).json({ message: result.error });
    }
    
    res.status(201).json({ message: 'Post liked successfully' });
  } catch (error) {
    console.error('Like post error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Unlike a post
router.delete('/:id/like', verifyToken, async (req, res) => {
  try {
    await postService.unlikePost(req.user.id, req.params.id);
    
    res.json({ message: 'Post unliked successfully' });
  } catch (error) {
    console.error('Unlike post error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all likes for a post
router.get('/:id/likes', verifyToken, async (req, res) => {
  try {
    const likes = await postService.getLikesByPost(req.params.id);
    
    res.json(likes);
  } catch (error) {
    console.error('Get post likes error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Add a comment to a post
router.post('/:id/comments', verifyToken, async (req, res) => {
  try {
    const { content } = req.body;
    
    if (!content || content.trim() === '') {
      return res.status(400).json({ message: 'Comment content is required' });
    }
    
    const comment = await postService.addComment(req.user.id, req.params.id, content);
    
    res.status(201).json(comment);
  } catch (error) {
    console.error('Add comment error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all comments for a post
router.get('/:id/comments', verifyToken, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    
    const comments = await postService.getCommentsByPost(req.params.id, page, limit);
    
    res.json(comments);
  } catch (error) {
    console.error('Get post comments error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;