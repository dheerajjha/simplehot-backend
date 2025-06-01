const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const { createClient } = require('redis');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_here';

// Redis client setup
let redisClient;
const connectRedis = async () => {
  try {
    redisClient = createClient({
      url: process.env.REDIS_URL || 'redis://localhost:6379'
    });
    
    redisClient.on('error', (err) => console.log('Redis Client Error', err));
    await redisClient.connect();
    console.log('Connected to Redis');
  } catch (error) {
    console.error('Redis connection error:', error);
  }
};
connectRedis();

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

// Get trending stocks
router.get('/trending', auth, async (req, res) => {
  try {
    // Check Redis cache first
    const cacheKey = 'trending_stocks';
    const cachedData = await redisClient.get(cacheKey);
    
    if (cachedData) {
      return res.status(200).json(JSON.parse(cachedData));
    }
    
    // If not in cache, fetch from database
    const stocks = await prisma.stock.findMany({
      orderBy: [
        { volume: 'desc' }
      ],
      take: 10
    });
    
    // Save to cache with expiration of 15 minutes
    await redisClient.set(cacheKey, JSON.stringify(stocks), {
      EX: 900
    });
    
    res.status(200).json(stocks);
  } catch (error) {
    console.error('Error getting trending stocks:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to retrieve trending stocks' });
  }
});

// Get stock by symbol
router.get('/:symbol', auth, async (req, res) => {
  try {
    const { symbol } = req.params;
    
    // Check Redis cache first
    const cacheKey = `stock:${symbol}`;
    const cachedData = await redisClient.get(cacheKey);
    
    if (cachedData) {
      return res.status(200).json(JSON.parse(cachedData));
    }
    
    // If not in cache, fetch from database
    const stock = await prisma.stock.findFirst({
      where: {
        symbol: {
          equals: symbol,
          mode: 'insensitive'
        }
      }
    });
    
    if (!stock) {
      return res.status(404).json({ error: 'Resource not found', details: `Stock with symbol '${symbol}' not found` });
    }
    
    // Save to cache with expiration of 5 minutes
    await redisClient.set(cacheKey, JSON.stringify(stock), {
      EX: 300
    });
    
    res.status(200).json(stock);
  } catch (error) {
    console.error('Error getting stock details:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to retrieve stock details' });
  }
});

// Search stocks
router.get('/search/:query', auth, async (req, res) => {
  try {
    const { query } = req.params;
    
    // Search in both symbol and name
    const stocks = await prisma.stock.findMany({
      where: {
        OR: [
          {
            symbol: {
              contains: query,
              mode: 'insensitive'
            }
          },
          {
            name: {
              contains: query,
              mode: 'insensitive'
            }
          }
        ]
      },
      take: 10
    });
    
    res.status(200).json(stocks);
  } catch (error) {
    console.error('Error searching stocks:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to search stocks' });
  }
});

// Get stock history
router.get('/:symbol/history', auth, async (req, res) => {
  try {
    const { symbol } = req.params;
    const { period } = req.query; // 'day', 'week', 'month', 'year'
    
    // Calculate date range based on period
    const endDate = new Date();
    let startDate = new Date();
    
    switch (period) {
      case 'week':
        startDate.setDate(endDate.getDate() - 7);
        break;
      case 'month':
        startDate.setMonth(endDate.getMonth() - 1);
        break;
      case 'year':
        startDate.setFullYear(endDate.getFullYear() - 1);
        break;
      default: // day or default
        startDate.setDate(endDate.getDate() - 1);
    }
    
    // Check Redis cache first
    const cacheKey = `stock_history:${symbol}:${period}`;
    const cachedData = await redisClient.get(cacheKey);
    
    if (cachedData) {
      return res.status(200).json(JSON.parse(cachedData));
    }
    
    // If not in cache, fetch from database
    const history = await prisma.stockHistory.findMany({
      where: {
        stockSymbol: symbol,
        date: {
          gte: startDate,
          lte: endDate
        }
      },
      orderBy: {
        date: 'asc'
      }
    });
    
    // Save to cache with expiration of 10 minutes
    await redisClient.set(cacheKey, JSON.stringify(history), {
      EX: 600
    });
    
    res.status(200).json(history);
  } catch (error) {
    console.error('Error getting stock history:', error);
    res.status(500).json({ error: 'Internal server error', details: 'Failed to retrieve stock history' });
  }
});

module.exports = router; 