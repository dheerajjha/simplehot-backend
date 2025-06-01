const express = require('express');
const authService = require('../services/authService');
const router = express.Router();

// Email validation function
const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

// Password validation function
const isValidPassword = (password) => {
  // Password must be at least 8 characters long and contain at least one letter and one number
  const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$/;
  return passwordRegex.test(password);
};

// Login route
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ message: 'Please provide email and password' });
    }
    
    // Validate email format
    if (!isValidEmail(email)) {
      return res.status(400).json({ message: 'Please provide a valid email address' });
    }
    
    // Find user by email
    const user = await authService.getUserByEmail(email);
    
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Check password
    const isMatch = await authService.verifyPassword(password, user.password);
    
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Generate JWT token
    const token = authService.generateToken(
      user,
      process.env.JWT_SECRET || 'your_jwt_secret_key_here'
    );
    
    res.json({ token });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Register route
router.post('/register', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ message: 'Please provide email and password' });
    }
    
    // Validate email format
    if (!isValidEmail(email)) {
      return res.status(400).json({ message: 'Please provide a valid email address' });
    }
    
    // Validate password strength
    if (!isValidPassword(password)) {
      return res.status(400).json({ 
        message: 'Password must be at least 8 characters long and contain at least one letter and one number' 
      });
    }
    
    // Check if user already exists
    const existingUser = await authService.getUserByEmail(email);
    
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }
    
    // Create new user
    const newUser = await authService.registerUser(email, password);
    
    // Generate JWT token
    const token = authService.generateToken(
      newUser,
      process.env.JWT_SECRET || 'your_jwt_secret_key_here'
    );
    
    res.status(201).json({ token });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Verify token route
router.get('/verify', async (req, res) => {
  try {
    const token = req.header('x-auth-token');
    
    if (!token) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }
    
    const { valid, decoded, error } = authService.verifyToken(
      token,
      process.env.JWT_SECRET || 'your_jwt_secret_key_here'
    );
    
    if (!valid) {
      return res.status(401).json({ message: 'Token is not valid', error });
    }
    
    // Check if user still exists in database
    const user = await authService.getUserByEmail(decoded.email);
    
    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }
    
    res.json({ user: { id: user.id, email: user.email } });
  } catch (error) {
    console.error('Verify token error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;