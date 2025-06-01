const prisma = require('./prisma');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Get user by email
const getUserByEmail = async (email) => {
  return prisma.user.findUnique({
    where: { email },
  });
};

// Register a new user
const registerUser = async (email, password) => {
  // Hash password
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);

  // Create user in database
  const user = await prisma.user.create({
    data: {
      email,
      password: hashedPassword,
    },
  });

  return user;
};

// Verify password
const verifyPassword = async (plainPassword, hashedPassword) => {
  return bcrypt.compare(plainPassword, hashedPassword);
};

// Generate JWT token
const generateToken = (user, secret, expiresIn = '1h') => {
  return jwt.sign(
    { id: user.id, email: user.email },
    secret,
    { expiresIn }
  );
};

// Verify token
const verifyToken = (token, secret) => {
  try {
    const decoded = jwt.verify(token, secret);
    return { valid: true, decoded };
  } catch (error) {
    return { valid: false, error: error.message };
  }
};

module.exports = {
  getUserByEmail,
  registerUser,
  verifyPassword,
  generateToken,
  verifyToken,
}; 