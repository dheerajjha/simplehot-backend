const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5001;
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
    password: '$2a$10$D4fGi0TGVEUkN.Z4Mj5uQeLQPL5xTF9Eu4uI1ur3VyHn5bDFVhwqS', // hashed 'password123'
  }
];

// Routes
app.get('/api/auth', (req, res) => {
  res.json({ message: 'Auth service is running' });
});

// Login route
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Find user by email
    const user = users.find(u => u.email === email);
    
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, email: user.email },
      JWT_SECRET,
      { expiresIn: '1h' }
    );
    
    res.json({ token });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Register route
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Check if user already exists
    if (users.some(u => u.email === email)) {
      return res.status(400).json({ message: 'User already exists' });
    }
    
    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    
    // Create new user (in a real app, save to database)
    const newUser = {
      id: users.length + 1,
      email,
      password: hashedPassword
    };
    
    users.push(newUser);
    
    // Generate JWT token
    const token = jwt.sign(
      { id: newUser.id, email: newUser.email },
      JWT_SECRET,
      { expiresIn: '1h' }
    );
    
    res.status(201).json({ token });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

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

// Protected route example
app.get('/api/auth/verify', verifyToken, (req, res) => {
  res.json({ user: req.user });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Auth service running on port ${PORT}`);
});