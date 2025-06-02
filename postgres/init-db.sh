#!/bin/bash

set -e
set -u

echo "Creating databases for SimpleHot application..."

# Function to create database if it doesn't exist
create_database_if_not_exists() {
    local db_name=$1
    echo "Checking if database $db_name exists..."
    if ! psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        echo "Creating database $db_name..."
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE $db_name;"
    else
        echo "Database $db_name already exists, skipping creation."
    fi
    echo "Granting privileges on $db_name..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $POSTGRES_USER;"
}

# Create consolidated application database and metabase database
create_database_if_not_exists "simplehot_db"
create_database_if_not_exists "metabase"

# All application tables in one database
echo "Setting up simplehot_db tables..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "simplehot_db" <<-EOSQL
    -- Users table (consolidated from auth and user services)
    CREATE TABLE IF NOT EXISTS "User" (
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
    CREATE UNIQUE INDEX IF NOT EXISTS "User_email_key" ON "User"("email");
    CREATE UNIQUE INDEX IF NOT EXISTS "User_username_key" ON "User"("username");

    -- Follow relationships
    CREATE TABLE IF NOT EXISTS "Follow" (
        "id" SERIAL NOT NULL,
        "followerId" INTEGER NOT NULL,
        "followingId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "Follow_pkey" PRIMARY KEY ("id")
    );
    CREATE UNIQUE INDEX IF NOT EXISTS "Follow_followerId_followingId_key" ON "Follow"("followerId", "followingId");

    -- Posts and social features
    CREATE TABLE IF NOT EXISTS "Post" (
        "id" SERIAL NOT NULL,
        "content" TEXT NOT NULL,
        "imageUrl" TEXT,
        "authorId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "Post_pkey" PRIMARY KEY ("id")
    );
    
    CREATE TABLE IF NOT EXISTS "Like" (
        "id" SERIAL NOT NULL,
        "userId" INTEGER NOT NULL,
        "postId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "Like_pkey" PRIMARY KEY ("id")
    );
    CREATE UNIQUE INDEX IF NOT EXISTS "Like_userId_postId_key" ON "Like"("userId", "postId");
    
    CREATE TABLE IF NOT EXISTS "Comment" (
        "id" SERIAL NOT NULL,
        "content" TEXT NOT NULL,
        "userId" INTEGER NOT NULL,
        "postId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "Comment_pkey" PRIMARY KEY ("id")
    );

    -- Stock data
    CREATE TABLE IF NOT EXISTS "Stock" (
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
    CREATE UNIQUE INDEX IF NOT EXISTS "Stock_symbol_key" ON "Stock"("symbol");
    
    CREATE TABLE IF NOT EXISTS "StockHistory" (
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
    CREATE UNIQUE INDEX IF NOT EXISTS "StockHistory_stockSymbol_date_key" ON "StockHistory"("stockSymbol", "date");

    -- Predictions
    CREATE TABLE IF NOT EXISTS "Prediction" (
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
    
    CREATE TABLE IF NOT EXISTS "PredictionLike" (
        "id" SERIAL NOT NULL,
        "predictionId" INTEGER NOT NULL,
        "userId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT "PredictionLike_pkey" PRIMARY KEY ("id")
    );
    CREATE UNIQUE INDEX IF NOT EXISTS "PredictionLike_userId_predictionId_key" ON "PredictionLike"("userId", "predictionId");
    
    CREATE TABLE IF NOT EXISTS "PredictionComment" (
        "id" SERIAL NOT NULL,
        "content" TEXT NOT NULL,
        "predictionId" INTEGER NOT NULL,
        "userId" INTEGER NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "PredictionComment_pkey" PRIMARY KEY ("id")
    );

    -- Add foreign key constraints
    DO \$\$
    BEGIN
        -- Follow constraints
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Follow_followerId_fkey') THEN
            ALTER TABLE "Follow" ADD CONSTRAINT "Follow_followerId_fkey" 
                FOREIGN KEY ("followerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Follow_followingId_fkey') THEN
            ALTER TABLE "Follow" ADD CONSTRAINT "Follow_followingId_fkey" 
                FOREIGN KEY ("followingId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;

        -- Post constraints
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Post_authorId_fkey') THEN
            ALTER TABLE "Post" ADD CONSTRAINT "Post_authorId_fkey" 
                FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;

        -- Like constraints
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Like_userId_fkey') THEN
            ALTER TABLE "Like" ADD CONSTRAINT "Like_userId_fkey" 
                FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Like_postId_fkey') THEN
            ALTER TABLE "Like" ADD CONSTRAINT "Like_postId_fkey" 
                FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;

        -- Comment constraints
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Comment_userId_fkey') THEN
            ALTER TABLE "Comment" ADD CONSTRAINT "Comment_userId_fkey" 
                FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Comment_postId_fkey') THEN
            ALTER TABLE "Comment" ADD CONSTRAINT "Comment_postId_fkey" 
                FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;

        -- Prediction constraints
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Prediction_userId_fkey') THEN
            ALTER TABLE "Prediction" ADD CONSTRAINT "Prediction_userId_fkey" 
                FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PredictionLike_predictionId_fkey') THEN
            ALTER TABLE "PredictionLike" ADD CONSTRAINT "PredictionLike_predictionId_fkey" 
                FOREIGN KEY ("predictionId") REFERENCES "Prediction"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PredictionLike_userId_fkey') THEN
            ALTER TABLE "PredictionLike" ADD CONSTRAINT "PredictionLike_userId_fkey" 
                FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PredictionComment_predictionId_fkey') THEN
            ALTER TABLE "PredictionComment" ADD CONSTRAINT "PredictionComment_predictionId_fkey" 
                FOREIGN KEY ("predictionId") REFERENCES "Prediction"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PredictionComment_userId_fkey') THEN
            ALTER TABLE "PredictionComment" ADD CONSTRAINT "PredictionComment_userId_fkey" 
                FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
    END
    \$\$;

    -- Insert sample stock data
    INSERT INTO "Stock" ("symbol", "name", "currentPrice", "change", "changePercent", "volume", "marketCap", "dayHigh", "dayLow", "yearHigh", "yearLow")
    SELECT 'RELIANCE', 'Reliance Industries', 2500.75, 25.50, 1.03, 3500000, 1500000000000, 2520.00, 2480.00, 2800.00, 2000.00
    WHERE NOT EXISTS (SELECT 1 FROM "Stock" WHERE symbol = 'RELIANCE');
    
    INSERT INTO "Stock" ("symbol", "name", "currentPrice", "change", "changePercent", "volume", "marketCap", "dayHigh", "dayLow", "yearHigh", "yearLow")
    SELECT 'TCS', 'Tata Consultancy Services', 3400.25, 45.30, 1.35, 2800000, 1200000000000, 3450.00, 3380.00, 3600.00, 3100.00
    WHERE NOT EXISTS (SELECT 1 FROM "Stock" WHERE symbol = 'TCS');
    
    INSERT INTO "Stock" ("symbol", "name", "currentPrice", "change", "changePercent", "volume", "marketCap", "dayHigh", "dayLow", "yearHigh", "yearLow")
    SELECT 'INFY', 'Infosys', 1500.50, -12.25, -0.81, 2100000, 950000000000, 1520.00, 1490.00, 1800.00, 1400.00
    WHERE NOT EXISTS (SELECT 1 FROM "Stock" WHERE symbol = 'INFY');
EOSQL

echo "Consolidated database setup complete! All tables created in simplehot_db"