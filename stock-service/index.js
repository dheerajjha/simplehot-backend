const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');
const helmet = require('helmet');
const cron = require('node-cron');
const { PrismaClient } = require('@prisma/client');

// Import routes
const stockRoutes = require('./src/routes/stockRoutes');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5004;
const prisma = new PrismaClient();

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Stock service is running' });
});

// API routes
app.use('/api/stocks', stockRoutes);

// Create some sample stock data if none exists
async function seedStockData() {
  try {
    const stocksCount = await prisma.stock.count();
    
    if (stocksCount === 0) {
      console.log('Seeding stock data...');
      
      // Create sample stocks
      await prisma.stock.createMany({
        data: [
          {
            symbol: 'RELIANCE',
            name: 'Reliance Industries',
            currentPrice: 2500.75,
            change: 25.50,
            changePercent: 1.03,
            volume: 3500000,
            marketCap: 1500000000000,
            dayHigh: 2520.00,
            dayLow: 2480.00,
            yearHigh: 2800.00,
            yearLow: 2000.00
          },
          {
            symbol: 'TCS',
            name: 'Tata Consultancy Services',
            currentPrice: 3400.25,
            change: 45.30,
            changePercent: 1.35,
            volume: 2800000,
            marketCap: 1200000000000,
            dayHigh: 3450.00,
            dayLow: 3380.00,
            yearHigh: 3600.00,
            yearLow: 3100.00
          },
          {
            symbol: 'INFY',
            name: 'Infosys',
            currentPrice: 1500.50,
            change: -12.25,
            changePercent: -0.81,
            volume: 2100000,
            marketCap: 950000000000,
            dayHigh: 1520.00,
            dayLow: 1490.00,
            yearHigh: 1800.00,
            yearLow: 1400.00
          }
        ]
      });
      
      console.log('Stock data seeded successfully');
    }
  } catch (error) {
    console.error('Error seeding stock data:', error);
  }
}

// Schedule job to update stock prices
cron.schedule('*/30 * * * *', async () => {
  try {
    console.log('Running stock update job');
    // This would normally update stock prices from an external API
    // For now, just generate random price changes
    
    const stocks = await prisma.stock.findMany();
    
    for (const stock of stocks) {
      // Generate random price movement (-1.5% to +1.5%)
      const changePercent = (Math.random() * 3 - 1.5);
      const change = stock.currentPrice * changePercent / 100;
      const newPrice = stock.currentPrice + change;
      
      // Update stock with new price
      await prisma.stock.update({
        where: { id: stock.id },
        data: {
          currentPrice: newPrice,
          change,
          changePercent,
          lastUpdated: new Date()
        }
      });
      
      // Create historical data point
      await prisma.stockHistory.create({
        data: {
          stockSymbol: stock.symbol,
          open: stock.currentPrice,
          high: Math.max(stock.currentPrice, newPrice),
          low: Math.min(stock.currentPrice, newPrice),
          close: newPrice,
          volume: Math.floor(Math.random() * 1000000 + 500000)
        }
      });
    }
    
    console.log(`Updated prices for ${stocks.length} stocks`);
  } catch (error) {
    console.error('Stock update job error:', error);
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    service: 'stock-service',
    timestamp: new Date().toISOString()
  });
});

// Start the server
app.listen(PORT, async () => {
  console.log(`Stock service running on port ${PORT}`);
  
  // Seed initial stock data
  await seedStockData();
}); 