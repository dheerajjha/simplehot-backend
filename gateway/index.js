const express = require('express');
const proxy = require('express-http-proxy');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5050;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Constants for service URLs (from environment variables or default for local development)
const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://localhost:5001';
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:5002';

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

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Gateway service running on port ${PORT}`);
}); 