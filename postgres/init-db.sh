#!/bin/bash

set -e
set -u

echo "Creating databases for SimpleHot microservices..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE auth_db;
    GRANT ALL PRIVILEGES ON DATABASE auth_db TO $POSTGRES_USER;
    
    CREATE DATABASE user_db;
    GRANT ALL PRIVILEGES ON DATABASE user_db TO $POSTGRES_USER;
    
    CREATE DATABASE post_db;
    GRANT ALL PRIVILEGES ON DATABASE post_db TO $POSTGRES_USER;
    
    CREATE DATABASE stock_db;
    GRANT ALL PRIVILEGES ON DATABASE stock_db TO $POSTGRES_USER;
    
    CREATE DATABASE prediction_db;
    GRANT ALL PRIVILEGES ON DATABASE prediction_db TO $POSTGRES_USER;
EOSQL

# Auth Service tables
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "auth_db" <<-EOSQL
    CREATE TABLE "User" (
        "id" SERIAL NOT NULL,
        "email" TEXT NOT NULL,
        "password" TEXT NOT NULL,
        "name" TEXT,
        "username" TEXT,
        "bio" TEXT,
        "profileImageUrl" TEXT,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "User_pkey" PRIMARY KEY ("id")
    );
    CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
    CREATE UNIQUE INDEX "User_username_key" ON "User"("username");
EOSQL

# Post Service tables
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "post_db" <<-EOSQL
    CREATE TABLE "Post" (
        "id" SERIAL NOT NULL,
        "content" TEXT NOT NULL,
        "imageUrl" TEXT,
        "authorId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "Post_pkey" PRIMARY KEY ("id")
    );
    
    CREATE TABLE "Like" (
        "id" SERIAL NOT NULL,
        "userId" INTEGER NOT NULL,
        "postId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "Like_pkey" PRIMARY KEY ("id")
    );
    
    CREATE TABLE "Comment" (
        "id" SERIAL NOT NULL,
        "content" TEXT NOT NULL,
        "userId" INTEGER NOT NULL,
        "postId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "Comment_pkey" PRIMARY KEY ("id")
    );
    
    ALTER TABLE "Like" ADD CONSTRAINT "Like_postId_fkey" 
        FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
    
    ALTER TABLE "Comment" ADD CONSTRAINT "Comment_postId_fkey" 
        FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
    
    CREATE UNIQUE INDEX "Like_userId_postId_key" ON "Like"("userId", "postId");
EOSQL

# Stock Service tables
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "stock_db" <<-EOSQL
    CREATE TABLE "Stock" (
        "id" SERIAL NOT NULL,
        "symbol" TEXT NOT NULL,
        "name" TEXT NOT NULL,
        "currentPrice" DOUBLE PRECISION NOT NULL,
        "change" DOUBLE PRECISION,
        "changePercent" DOUBLE PRECISION,
        "volume" INTEGER,
        "marketCap" BIGINT,
        "dayHigh" DOUBLE PRECISION,
        "dayLow" DOUBLE PRECISION,
        "yearHigh" DOUBLE PRECISION,
        "yearLow" DOUBLE PRECISION,
        "lastUpdated" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "Stock_pkey" PRIMARY KEY ("id")
    );
    
    CREATE TABLE "StockHistory" (
        "id" SERIAL NOT NULL,
        "stockSymbol" TEXT NOT NULL,
        "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "open" DOUBLE PRECISION NOT NULL,
        "high" DOUBLE PRECISION NOT NULL,
        "low" DOUBLE PRECISION NOT NULL,
        "close" DOUBLE PRECISION NOT NULL,
        "volume" INTEGER NOT NULL,
        CONSTRAINT "StockHistory_pkey" PRIMARY KEY ("id")
    );
    
    CREATE UNIQUE INDEX "Stock_symbol_key" ON "Stock"("symbol");
    CREATE UNIQUE INDEX "StockHistory_stockSymbol_date_key" ON "StockHistory"("stockSymbol", "date");
    
    -- Insert some sample stock data
    INSERT INTO "Stock" ("symbol", "name", "currentPrice", "change", "changePercent", "volume", "marketCap", "dayHigh", "dayLow", "yearHigh", "yearLow")
    VALUES 
        ('RELIANCE', 'Reliance Industries', 2500.75, 25.50, 1.03, 3500000, 1500000000000, 2520.00, 2480.00, 2800.00, 2000.00),
        ('TCS', 'Tata Consultancy Services', 3400.25, 45.30, 1.35, 2800000, 1200000000000, 3450.00, 3380.00, 3600.00, 3100.00),
        ('INFY', 'Infosys', 1500.50, -12.25, -0.81, 2100000, 950000000000, 1520.00, 1490.00, 1800.00, 1400.00);
EOSQL

# Prediction Service tables
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "prediction_db" <<-EOSQL
    CREATE TABLE "Prediction" (
        "id" SERIAL NOT NULL,
        "stockSymbol" TEXT NOT NULL,
        "stockName" TEXT NOT NULL,
        "userId" INTEGER NOT NULL,
        "targetPrice" DOUBLE PRECISION NOT NULL,
        "currentPrice" DOUBLE PRECISION NOT NULL,
        "targetDate" TIMESTAMP(3) NOT NULL,
        "direction" TEXT NOT NULL,
        "description" TEXT,
        "status" TEXT NOT NULL DEFAULT 'pending',
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        "percentageDifference" DOUBLE PRECISION,
        CONSTRAINT "Prediction_pkey" PRIMARY KEY ("id")
    );
    
    CREATE TABLE "PredictionLike" (
        "id" SERIAL NOT NULL,
        "predictionId" INTEGER NOT NULL,
        "userId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "PredictionLike_pkey" PRIMARY KEY ("id")
    );
    
    CREATE TABLE "PredictionComment" (
        "id" SERIAL NOT NULL,
        "content" TEXT NOT NULL,
        "predictionId" INTEGER NOT NULL,
        "userId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "PredictionComment_pkey" PRIMARY KEY ("id")
    );
    
    ALTER TABLE "PredictionLike" ADD CONSTRAINT "PredictionLike_predictionId_fkey" 
        FOREIGN KEY ("predictionId") REFERENCES "Prediction"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
    
    ALTER TABLE "PredictionComment" ADD CONSTRAINT "PredictionComment_predictionId_fkey" 
        FOREIGN KEY ("predictionId") REFERENCES "Prediction"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
    
    CREATE UNIQUE INDEX "PredictionLike_userId_predictionId_key" ON "PredictionLike"("userId", "predictionId");
EOSQL

# User Service tables
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "user_db" <<-EOSQL
    CREATE TABLE "User" (
        "id" SERIAL NOT NULL,
        "email" TEXT NOT NULL,
        "name" TEXT,
        "username" TEXT,
        "bio" TEXT,
        "profileImageUrl" TEXT,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "User_pkey" PRIMARY KEY ("id")
    );
    
    CREATE TABLE "Follow" (
        "id" SERIAL NOT NULL,
        "followerId" INTEGER NOT NULL,
        "followingId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "Follow_pkey" PRIMARY KEY ("id")
    );
    
    CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
    CREATE UNIQUE INDEX "User_username_key" ON "User"("username");
    CREATE UNIQUE INDEX "Follow_followerId_followingId_key" ON "Follow"("followerId", "followingId");
EOSQL

echo "All databases and tables have been created successfully" 