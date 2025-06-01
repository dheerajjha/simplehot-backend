const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');

// Import routes
const userRoutes = require('./src/routes/userRoutes');
const postRoutes = require('./src/routes/postRoutes');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5002;
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_here';

// Middleware
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// JWT decoding middleware
// This extracts the user info from token but doesn't validate it (that's done in the auth service)
app.use((req, res, next) => {
  const token = req.header('x-auth-token');
  
  if (token) {
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      req.user = decoded;
    } catch (error) {
      // Don't return error, just don't set user object
      console.error('Token decoding error:', error.message);
    }
  }
  
  next();
});

// Routes
app.get('/api/users', (req, res) => {
  res.json({ message: 'User service is running' });
});

// API routes
app.use('/api/users', userRoutes);
app.use('/api/posts', postRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`User service running on port ${PORT}`);
}); 