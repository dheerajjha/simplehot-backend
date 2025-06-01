const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');
const helmet = require('helmet');
const cron = require('node-cron');
const { PrismaClient } = require('@prisma/client');
const axios = require('axios');

// Import routes
const predictionRoutes = require('./src/routes/predictionRoutes');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5005;
const prisma = new PrismaClient();
const STOCK_SERVICE_URL = process.env.STOCK_SERVICE_URL || 'http://localhost:5004';

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Prediction service is running' });
});

// API routes
app.use('/api/predictions', predictionRoutes);

// Schedule job to verify predictions
cron.schedule('0 0 * * *', async () => {
  try {
    console.log('Running prediction verification job');
    const today = new Date();
    
    // Find predictions that have reached their target date
    const predictions = await prisma.prediction.findMany({
      where: {
        status: 'pending',
        targetDate: {
          lte: today
        }
      }
    });
    
    console.log(`Found ${predictions.length} predictions to verify`);
    
    // This would normally check the current stock price from the stock service
    // For now, just mark some as correct and some as incorrect
    for (const prediction of predictions) {
      const status = Math.random() > 0.5 ? 'correct' : 'incorrect';
      
      await prisma.prediction.update({
        where: { id: prediction.id },
        data: { status }
      });
      
      console.log(`Updated prediction ${prediction.id} to ${status}`);
    }
  } catch (error) {
    console.error('Prediction verification job error:', error);
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    service: 'prediction-service',
    timestamp: new Date().toISOString()
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Prediction service running on port ${PORT}`);
}); 