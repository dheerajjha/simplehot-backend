const express = require('express');
const proxy = require('express-http-proxy');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');
const rateLimit = require('express-rate-limit');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5050;

// Rate limiting middleware
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: { error: 'Too many requests, please try again later' }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use('/api/', apiLimiter);

// Constants for service URLs (from environment variables or default for local development)
const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://localhost:5001';
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:5002';
const POST_SERVICE_URL = process.env.POST_SERVICE_URL || 'http://localhost:5003';
const STOCK_SERVICE_URL = process.env.STOCK_SERVICE_URL || 'http://localhost:5004';
const PREDICTION_SERVICE_URL = process.env.PREDICTION_SERVICE_URL || 'http://localhost:5005';

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Gateway API is running' });
});

// Auth service proxy routes
app.use('/api/auth', proxy(AUTH_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    return `/api/auth${req.url}`;
  }
}));

// User service proxy routes
app.use('/api/users', proxy(USER_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    return `/api/users${req.url}`;
  }
}));

// Posts service proxy routes
app.use('/api/posts', proxy(POST_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    return `/api/posts${req.url}`;
  }
}));

// Stock service proxy routes
app.use('/api/stocks', proxy(STOCK_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    return `/api/stocks${req.url}`;
  }
}));

// Prediction service proxy routes
app.use('/api/predictions', proxy(PREDICTION_SERVICE_URL, {
  proxyReqPathResolver: (req) => {
    return `/api/predictions${req.url}`;
  }
}));

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Simple health check for the gateway itself
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        gateway: 'up'
      }
    };
    
    res.status(200).json(health);
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`Gateway service running on port ${PORT}`);
}); 