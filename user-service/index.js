const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5002;
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_here';

// Middleware
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Mock users database (in a real app, you would use a database)
const users = [
  {
    id: 1,
    email: 'user@example.com',
    name: 'Test User',
    role: 'user'
  },
  {
    id: 2,
    email: 'admin@example.com',
    name: 'Admin User',
    role: 'admin'
  }
];

// Verify token middleware
const verifyToken = (req, res, next) => {
  const token = req.header('x-auth-token');
  
  if (!token) {
    return res.status(401).json({ message: 'No token, authorization denied' });
  }
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Token is not valid' });
  }
};

// Routes
app.get('/api/users', (req, res) => {
  res.json({ message: 'User service is running' });
});

// Get all users (protected route)
app.get('/api/users/all', verifyToken, (req, res) => {
  // In a real app, you might want to check for admin role here
  const safeUsers = users.map(({ password, ...rest }) => rest);
  res.json(safeUsers);
});

// Get user profile (protected route)
app.get('/api/users/profile', verifyToken, (req, res) => {
  const user = users.find(u => u.id === req.user.id);
  
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  const { password, ...userWithoutPassword } = user;
  res.json(userWithoutPassword);
});

// Update user profile (protected route)
app.put('/api/users/profile', verifyToken, (req, res) => {
  const userIndex = users.findIndex(u => u.id === req.user.id);
  
  if (userIndex === -1) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  // Update user data (excluding sensitive fields)
  const { name } = req.body;
  
  users[userIndex] = {
    ...users[userIndex],
    name: name || users[userIndex].name
  };
  
  const { password, ...userWithoutPassword } = users[userIndex];
  res.json(userWithoutPassword);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`User service running on port ${PORT}`);
}); 