const express = require('express');
const userService = require('../services/userService');
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

// Get the authenticated user's profile
router.get('/profile', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await userService.getUserById(userId);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user by ID
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const user = await userService.getUserById(req.params.id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Check if the authenticated user is following this user
    const isFollowing = await userService.isFollowing(req.user.id, req.params.id);
    
    res.json({
      ...user,
      isFollowing,
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update user profile
router.put('/profile', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, username, bio, profileImageUrl, coverImageUrl } = req.body;
    
    // Validate data
    if (username) {
      // Check if username is already taken by another user
      const existingUser = await userService.getUserByUsername(username);
      if (existingUser && existingUser.id !== userId) {
        return res.status(400).json({ message: 'Username already taken' });
      }
    }
    
    const updatedUser = await userService.updateUser(userId, {
      name,
      username,
      bio,
      profileImageUrl,
      coverImageUrl,
    });
    
    res.json(updatedUser);
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user's followers
router.get('/:id/followers', verifyToken, async (req, res) => {
  try {
    const followers = await userService.getFollowers(req.params.id);
    res.json(followers);
  } catch (error) {
    console.error('Get followers error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get users that a user is following
router.get('/:id/following', verifyToken, async (req, res) => {
  try {
    const following = await userService.getFollowing(req.params.id);
    res.json(following);
  } catch (error) {
    console.error('Get following error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Follow a user
router.post('/:id/follow', verifyToken, async (req, res) => {
  try {
    const followerId = req.user.id;
    const followingId = req.params.id;
    
    // Check if trying to follow self
    if (followerId === parseInt(followingId)) {
      return res.status(400).json({ message: 'Cannot follow yourself' });
    }
    
    const result = await userService.followUser(followerId, followingId);
    
    if (result.error) {
      return res.status(400).json({ message: result.error });
    }
    
    res.status(201).json({ message: 'Successfully followed user' });
  } catch (error) {
    console.error('Follow user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Unfollow a user
router.delete('/:id/follow', verifyToken, async (req, res) => {
  try {
    const followerId = req.user.id;
    const followingId = req.params.id;
    
    await userService.unfollowUser(followerId, followingId);
    
    res.json({ message: 'Successfully unfollowed user' });
  } catch (error) {
    console.error('Unfollow user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user feed (posts from followed users)
router.get('/feed', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    
    const feed = await userService.getFeed(userId, page, limit);
    
    res.json(feed);
  } catch (error) {
    console.error('Get feed error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router; 