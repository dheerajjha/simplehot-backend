const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_here';

// Auth middleware
const auth = async (req, res, next) => {
  const token = req.header('x-auth-token');
  
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized', details: 'No token provided' });
  }
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Unauthorized', details: 'Invalid or expired token' });
  }
};

// Create a post
router.post('/', auth, async (req, res) => {
  try {
    const { content, imageUrl } = req.body;
    
    if (!content) {
      return res.status(400).json({ 
        error: 'Invalid request data', 
        details: 'Content is required' 
      });
    }
    
    const post = await prisma.post.create({
      data: {
        content,
        imageUrl,
        authorId: req.user.id
      }
    });
    
    res.status(201).json({
      id: post.id,
      userId: post.authorId,
      content: post.content,
      imageUrl: post.imageUrl,
      createdAt: post.createdAt,
      likes: [],
      commentCount: 0
    });
  } catch (error) {
    console.error('Create post error:', error);
    res.status(500).json({ 
      error: 'Internal server error', 
      details: 'Failed to create post' 
    });
  }
});

// Get post by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    
    const post = await prisma.post.findUnique({
      where: { id: parseInt(id) },
      include: {
        likes: true,
        comments: {
          select: {
            id: true
          }
        }
      }
    });
    
    if (!post) {
      return res.status(404).json({ 
        error: 'Resource not found', 
        details: `Post with ID '${id}' not found` 
      });
    }
    
    res.status(200).json({
      id: post.id,
      userId: post.authorId,
      content: post.content,
      imageUrl: post.imageUrl,
      createdAt: post.createdAt,
      likes: post.likes.map(like => like.userId),
      commentCount: post.comments.length
    });
  } catch (error) {
    console.error('Get post error:', error);
    res.status(500).json({ 
      error: 'Internal server error', 
      details: 'Failed to retrieve post' 
    });
  }
});

// Get posts by user
router.get('/user/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    
    const posts = await prisma.post.findMany({
      where: { authorId: parseInt(userId) },
      include: {
        likes: true,
        comments: {
          select: {
            id: true
          }
        }
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit
    });
    
    const formattedPosts = posts.map(post => ({
      id: post.id,
      userId: post.authorId,
      content: post.content,
      imageUrl: post.imageUrl,
      createdAt: post.createdAt,
      likes: post.likes.map(like => like.userId),
      commentCount: post.comments.length
    }));
    
    res.status(200).json(formattedPosts);
  } catch (error) {
    console.error('Get user posts error:', error);
    res.status(500).json({ 
      error: 'Internal server error', 
      details: 'Failed to retrieve posts' 
    });
  }
});

// Like a post
router.post('/:id/like', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    
    // Check if post exists
    const post = await prisma.post.findUnique({
      where: { id: parseInt(id) }
    });
    
    if (!post) {
      return res.status(404).json({ 
        error: 'Resource not found', 
        details: `Post with ID '${id}' not found` 
      });
    }
    
    // Check if user already liked the post
    const existingLike = await prisma.like.findFirst({
      where: {
        userId: parseInt(userId),
        postId: parseInt(id)
      }
    });
    
    if (existingLike) {
      return res.status(400).json({ 
        error: 'Invalid request data', 
        details: 'User already liked this post' 
      });
    }
    
    // Create like
    await prisma.like.create({
      data: {
        userId: parseInt(userId),
        postId: parseInt(id)
      }
    });
    
    res.status(200).json({
      success: true,
      message: 'Post liked successfully'
    });
  } catch (error) {
    console.error('Like post error:', error);
    res.status(500).json({ 
      error: 'Internal server error', 
      details: 'Failed to like post' 
    });
  }
});

// Unlike a post
router.delete('/:id/like', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    
    // Delete like if it exists
    const result = await prisma.like.deleteMany({
      where: {
        userId: parseInt(userId),
        postId: parseInt(id)
      }
    });
    
    if (result.count === 0) {
      return res.status(400).json({ 
        error: 'Invalid request data', 
        details: 'User has not liked this post' 
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'Post unliked successfully'
    });
  } catch (error) {
    console.error('Unlike post error:', error);
    res.status(500).json({ 
      error: 'Internal server error', 
      details: 'Failed to unlike post' 
    });
  }
});

// Get post likes
router.get('/:id/likes', auth, async (req, res) => {
  try {
    const { id } = req.params;
    
    const likes = await prisma.like.findMany({
      where: { postId: parseInt(id) },
      select: { userId: true }
    });
    
    res.status(200).json(likes.map(like => like.userId));
  } catch (error) {
    console.error('Get post likes error:', error);
    res.status(500).json({ 
      error: 'Internal server error', 
      details: 'Failed to retrieve likes' 
    });
  }
});

// Add comment to post
router.post('/:id/comments', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    const userId = req.user.id;
    
    if (!content) {
      return res.status(400).json({ 
        error: 'Invalid request data', 
        details: 'Comment content is required' 
      });
    }
    
    // Check if post exists
    const post = await prisma.post.findUnique({
      where: { id: parseInt(id) }
    });
    
    if (!post) {
      return res.status(404).json({ 
        error: 'Resource not found', 
        details: `Post with ID '${id}' not found` 
      });
    }
    
    // Create comment
    const comment = await prisma.comment.create({
      data: {
        content,
        userId: parseInt(userId),
        postId: parseInt(id)
      }
    });
    
    res.status(201).json({
      id: comment.id,
      postId: comment.postId,
      userId: comment.userId,
      content: comment.content,
      createdAt: comment.createdAt
    });
  } catch (error) {
    console.error('Add comment error:', error);
    res.status(500).json({ 
      error: 'Internal server error', 
      details: 'Failed to add comment' 
    });
  }
});

// Get post comments
router.get('/:id/comments', auth, async (req, res) => {
  try {
    const { id } = req.params;
    
    const comments = await prisma.comment.findMany({
      where: { postId: parseInt(id) },
      orderBy: { createdAt: 'desc' }
    });
    
    // In a real implementation, we would fetch user info from the user service
    // For now, we'll just return the comment data
    const formattedComments = comments.map(comment => ({
      id: comment.id,
      postId: comment.postId,
      userId: comment.userId,
      content: comment.content,
      createdAt: comment.createdAt,
      user: {
        // These would normally be fetched from the user service
        name: `User ${comment.userId}`,
        username: `user${comment.userId}`,
        profileImageUrl: null
      }
    }));
    
    res.status(200).json(formattedComments);
  } catch (error) {
    console.error('Get comments error:', error);
    res.status(500).json({ 
      error: 'Internal server error', 
      details: 'Failed to retrieve comments' 
    });
  }
});

module.exports = router;