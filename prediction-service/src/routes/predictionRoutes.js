const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const axios = require('axios');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_here';
const STOCK_SERVICE_URL = process.env.STOCK_SERVICE_URL || 'http://localhost:5004';

// Auth middleware
const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'Unauthorized', details: 'No token provided' });
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Unauthorized', details: 'Invalid or expired token' });
  }
};

// Get trending predictions
router.get('/trending', auth, async (req, res) => {
  try {
    const predictions = await prisma.prediction.findMany({
      where: {
        status: 'pending' // Only show pending predictions
      },
      orderBy: [
        { createdAt: 'desc' }
      ],
      take: 10,
      include: {
        likes: true,
        _count: {
          select: {
            comments: true
          }
        }
      }
    });

    // Format the response
    const formattedPredictions = predictions.map(prediction => ({
      ...prediction,
      likes: prediction.likes,
      commentCount: prediction._count.comments,
      _count: undefined,
      // Add mock user data since we can't access the user service directly
      user: {
        name: `User ${prediction.userId}`,
        username: `user${prediction.userId}`,
        profileImageUrl: null
      }
    }));

    res.status(200).json(formattedPredictions);
  } catch (error) {
    console.error('Error getting trending predictions:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to retrieve trending predictions' });
  }
});

// Get predictions for a specific stock
router.get('/stock/:symbol', auth, async (req, res) => {
  try {
    const { symbol } = req.params;
    
    // Get predictions for the stock
    const predictions = await prisma.prediction.findMany({
      where: {
        stockSymbol: {
          equals: symbol,
          mode: 'insensitive'
        }
      },
      orderBy: [
        { createdAt: 'desc' }
      ],
      include: {
        likes: true,
        _count: {
          select: {
            comments: true
          }
        }
      }
    });

    // Format the response
    const formattedPredictions = predictions.map(prediction => ({
      ...prediction,
      likes: prediction.likes,
      commentCount: prediction._count.comments,
      _count: undefined,
      // Add mock user data since we can't access the user service directly
      user: {
        name: `User ${prediction.userId}`,
        username: `user${prediction.userId}`,
        profileImageUrl: null
      }
    }));

    res.status(200).json(formattedPredictions);
  } catch (error) {
    console.error('Error getting predictions for stock:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to retrieve predictions for stock' });
  }
});

// Get predictions by user ID
router.get('/user/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Convert userId to number
    const userIdNum = parseInt(userId, 10);
    
    if (isNaN(userIdNum)) {
      return res.status(400).json({ error: 'Invalid request data', details: 'User ID must be a number' });
    }
    
    // Get predictions for the user
    const predictions = await prisma.prediction.findMany({
      where: {
        userId: userIdNum
      },
      orderBy: [
        { createdAt: 'desc' }
      ],
      include: {
        likes: true,
        _count: {
          select: {
            comments: true
          }
        }
      }
    });

    // Format the response
    const formattedPredictions = predictions.map(prediction => ({
      ...prediction,
      likes: prediction.likes,
      commentCount: prediction._count.comments,
      _count: undefined
    }));

    res.status(200).json(formattedPredictions);
  } catch (error) {
    console.error('Error getting user predictions:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to retrieve user predictions' });
  }
});

// Create a new prediction
router.post('/', auth, async (req, res) => {
  try {
    const { stockSymbol, stockName, targetPrice, targetDate, direction, description } = req.body;
    const userId = req.user.id;

    // Validate required fields
    if (!stockSymbol || !stockName || !targetPrice || !targetDate || !direction) {
      return res.status(400).json({ error: 'Invalid request data', details: 'Missing required fields' });
    }

    // Get current stock price from stock service
    let currentPrice;
    try {
      const stockResponse = await axios.get(`${STOCK_SERVICE_URL}/api/stocks/${stockSymbol}`, {
        headers: {
          Authorization: `Bearer ${req.header('Authorization')?.replace('Bearer ', '')}`
        }
      });
      currentPrice = stockResponse.data.currentPrice;
    } catch (error) {
      // Fallback if stock service is unavailable
      currentPrice = targetPrice * 0.95; // Assume current price is 5% less than target
      console.warn(`Could not fetch current price for ${stockSymbol}, using fallback value`);
    }

    // Calculate percentage difference
    const percentageDifference = ((targetPrice - currentPrice) / currentPrice) * 100;

    // Create the prediction
    const prediction = await prisma.prediction.create({
      data: {
        stockSymbol,
        stockName,
        userId,
        targetPrice,
        currentPrice,
        targetDate: new Date(targetDate),
        direction,
        description,
        status: 'pending',
        percentageDifference
      },
      include: {
        likes: true,
        _count: {
          select: {
            comments: true
          }
        }
      }
    });

    // Format the response
    const formattedPrediction = {
      ...prediction,
      likes: prediction.likes,
      commentCount: prediction._count.comments,
      _count: undefined
    };

    res.status(201).json(formattedPrediction);
  } catch (error) {
    console.error('Error creating prediction:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to create prediction' });
  }
});

// Like a prediction
router.post('/:id/like', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Check if prediction exists
    const prediction = await prisma.prediction.findUnique({
      where: { id: parseInt(id) }
    });

    if (!prediction) {
      return res.status(404).json({ error: 'Resource not found', details: 'Prediction not found' });
    }

    // Check if user already liked this prediction
    const existingLike = await prisma.predictionLike.findFirst({
      where: {
        predictionId: parseInt(id),
        userId
      }
    });

    if (existingLike) {
      return res.status(400).json({ error: 'Invalid request data', details: 'You already liked this prediction' });
    }

    // Create the like
    await prisma.predictionLike.create({
      data: {
        predictionId: parseInt(id),
        userId
      }
    });

    res.status(201).json({ message: 'Prediction liked successfully' });
  } catch (error) {
    console.error('Error liking prediction:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to like prediction' });
  }
});

// Unlike a prediction
router.delete('/:id/like', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Check if prediction exists
    const prediction = await prisma.prediction.findUnique({
      where: { id: parseInt(id) }
    });

    if (!prediction) {
      return res.status(404).json({ error: 'Resource not found', details: 'Prediction not found' });
    }

    // Check if user liked this prediction
    const existingLike = await prisma.predictionLike.findFirst({
      where: {
        predictionId: parseInt(id),
        userId
      }
    });

    if (!existingLike) {
      return res.status(400).json({ error: 'Invalid request data', details: 'You have not liked this prediction' });
    }

    // Delete the like
    await prisma.predictionLike.delete({
      where: {
        id: existingLike.id
      }
    });

    res.status(200).json({ message: 'Prediction unliked successfully' });
  } catch (error) {
    console.error('Error unliking prediction:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to unlike prediction' });
  }
});

// Add a comment to a prediction
router.post('/:id/comment', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    const userId = req.user.id;

    // Validate content
    if (!content || content.trim() === '') {
      return res.status(400).json({ error: 'Invalid request data', details: 'Comment content is required' });
    }

    // Check if prediction exists
    const prediction = await prisma.prediction.findUnique({
      where: { id: parseInt(id) }
    });

    if (!prediction) {
      return res.status(404).json({ error: 'Resource not found', details: 'Prediction not found' });
    }

    // Create the comment
    const comment = await prisma.predictionComment.create({
      data: {
        content,
        predictionId: parseInt(id),
        userId
      }
    });

    res.status(201).json(comment);
  } catch (error) {
    console.error('Error adding comment:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to add comment' });
  }
});

// Get comments for a prediction
router.get('/:id/comments', auth, async (req, res) => {
  try {
    const { id } = req.params;

    // Check if prediction exists
    const prediction = await prisma.prediction.findUnique({
      where: { id: parseInt(id) }
    });

    if (!prediction) {
      return res.status(404).json({ error: 'Resource not found', details: 'Prediction not found' });
    }

    // Get comments
    const comments = await prisma.predictionComment.findMany({
      where: { predictionId: parseInt(id) },
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            name: true,
            username: true,
            profileImageUrl: true
          }
        }
      }
    });

    res.status(200).json(comments);
  } catch (error) {
    console.error('Error getting comments:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to get comments' });
  }
});

module.exports = router; 