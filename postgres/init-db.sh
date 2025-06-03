#!/bin/bash

set -e
set -u

# Set default values for environment variables if not provided
export POSTGRES_USER=${POSTGRES_USER:-postgres}
export POSTGRES_DB=${POSTGRES_DB:-postgres}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}

echo "=== SimpleHot Database Initialization Script ==="
echo "POSTGRES_USER: $POSTGRES_USER"
echo "POSTGRES_DB: $POSTGRES_DB"
echo "Script started at: $(date)"
echo "================================================"

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
            echo "PostgreSQL is ready!"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: PostgreSQL not ready yet, waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: PostgreSQL failed to become ready after $max_attempts attempts"
    exit 1
}

# Function to create database if it doesn't exist
create_database_if_not_exists() {
    local db_name=$1
    echo "Checking if database '$db_name' exists..."
    
    # Check if database exists
    if psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name'" | grep -q 1; then
        echo "✓ Database '$db_name' already exists, skipping creation."
    else
        echo "Creating database '$db_name'..."
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE \"$db_name\";"
        echo "✓ Database '$db_name' created successfully."
    fi
    
    echo "Granting privileges on '$db_name' to '$POSTGRES_USER'..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "GRANT ALL PRIVILEGES ON DATABASE \"$db_name\" TO \"$POSTGRES_USER\";"
    echo "✓ Privileges granted on '$db_name'."
}

# Function to check if we can connect to a specific database
test_database_connection() {
    local db_name=$1
    echo "Testing connection to database '$db_name'..."
    
    if psql -U "$POSTGRES_USER" -d "$db_name" -c "SELECT current_database(), current_user, version();" >/dev/null 2>&1; then
        echo "✓ Successfully connected to database '$db_name'."
        return 0
    else
        echo "✗ Failed to connect to database '$db_name'."
        return 1
    fi
}

# Function to setup all tables and constraints
setup_database_schema() {
    local db_name=$1
    echo "Setting up schema for database '$db_name'..."
    
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db_name" <<-EOSQL
        -- Enable extensions if needed
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
        
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
            "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
            "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
            "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
            "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
            "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "PredictionComment_pkey" PRIMARY KEY ("id")
        );

        -- Add foreign key constraints with better error handling
        DO \$\$
        BEGIN
            -- Follow constraints
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Follow_followerId_fkey') THEN
                ALTER TABLE "Follow" ADD CONSTRAINT "Follow_followerId_fkey" 
                    FOREIGN KEY ("followerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added Follow_followerId_fkey constraint';
            END IF;
            
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Follow_followingId_fkey') THEN
                ALTER TABLE "Follow" ADD CONSTRAINT "Follow_followingId_fkey" 
                    FOREIGN KEY ("followingId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added Follow_followingId_fkey constraint';
            END IF;

            -- Post constraints
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Post_authorId_fkey') THEN
                ALTER TABLE "Post" ADD CONSTRAINT "Post_authorId_fkey" 
                    FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added Post_authorId_fkey constraint';
            END IF;

            -- Like constraints
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Like_userId_fkey') THEN
                ALTER TABLE "Like" ADD CONSTRAINT "Like_userId_fkey" 
                    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added Like_userId_fkey constraint';
            END IF;
            
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Like_postId_fkey') THEN
                ALTER TABLE "Like" ADD CONSTRAINT "Like_postId_fkey" 
                    FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added Like_postId_fkey constraint';
            END IF;

            -- Comment constraints
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Comment_userId_fkey') THEN
                ALTER TABLE "Comment" ADD CONSTRAINT "Comment_userId_fkey" 
                    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added Comment_userId_fkey constraint';
            END IF;
            
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Comment_postId_fkey') THEN
                ALTER TABLE "Comment" ADD CONSTRAINT "Comment_postId_fkey" 
                    FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added Comment_postId_fkey constraint';
            END IF;

            -- Prediction constraints
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Prediction_userId_fkey') THEN
                ALTER TABLE "Prediction" ADD CONSTRAINT "Prediction_userId_fkey" 
                    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added Prediction_userId_fkey constraint';
            END IF;

            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PredictionLike_predictionId_fkey') THEN
                ALTER TABLE "PredictionLike" ADD CONSTRAINT "PredictionLike_predictionId_fkey" 
                    FOREIGN KEY ("predictionId") REFERENCES "Prediction"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added PredictionLike_predictionId_fkey constraint';
            END IF;
            
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PredictionLike_userId_fkey') THEN
                ALTER TABLE "PredictionLike" ADD CONSTRAINT "PredictionLike_userId_fkey" 
                    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added PredictionLike_userId_fkey constraint';
            END IF;

            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PredictionComment_predictionId_fkey') THEN
                ALTER TABLE "PredictionComment" ADD CONSTRAINT "PredictionComment_predictionId_fkey" 
                    FOREIGN KEY ("predictionId") REFERENCES "Prediction"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added PredictionComment_predictionId_fkey constraint';
            END IF;
            
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'PredictionComment_userId_fkey') THEN
                ALTER TABLE "PredictionComment" ADD CONSTRAINT "PredictionComment_userId_fkey" 
                    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
                RAISE NOTICE 'Added PredictionComment_userId_fkey constraint';
            END IF;
        END
        \$\$;
EOSQL

    echo "✓ Schema setup completed for '$db_name'."
}

# Function to insert sample data
insert_sample_data() {
    local db_name=$1
    echo "Inserting sample data into '$db_name'..."
    
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db_name" <<-EOSQL
        -- Insert sample stock data with better error handling
        INSERT INTO "Stock" ("symbol", "name", "currentPrice", "change", "changePercent", "volume", "marketCap", "dayHigh", "dayLow", "yearHigh", "yearLow")
        SELECT 'RELIANCE', 'Reliance Industries', 2500.75, 25.50, 1.03, 3500000, 1500000000000, 2520.00, 2480.00, 2800.00, 2000.00
        WHERE NOT EXISTS (SELECT 1 FROM "Stock" WHERE symbol = 'RELIANCE');
        
        INSERT INTO "Stock" ("symbol", "name", "currentPrice", "change", "changePercent", "volume", "marketCap", "dayHigh", "dayLow", "yearHigh", "yearLow")
        SELECT 'TCS', 'Tata Consultancy Services', 3400.25, 45.30, 1.35, 2800000, 1200000000000, 3450.00, 3380.00, 3600.00, 3100.00
        WHERE NOT EXISTS (SELECT 1 FROM "Stock" WHERE symbol = 'TCS');
        
        INSERT INTO "Stock" ("symbol", "name", "currentPrice", "change", "changePercent", "volume", "marketCap", "dayHigh", "dayLow", "yearHigh", "yearLow")
        SELECT 'INFY', 'Infosys', 1500.50, -12.25, -0.81, 2100000, 950000000000, 1520.00, 1490.00, 1800.00, 1400.00
        WHERE NOT EXISTS (SELECT 1 FROM "Stock" WHERE symbol = 'INFY');
        
        -- Add more sample stocks for better testing
        INSERT INTO "Stock" ("symbol", "name", "currentPrice", "change", "changePercent", "volume", "marketCap", "dayHigh", "dayLow", "yearHigh", "yearLow")
        SELECT 'HDFC', 'HDFC Bank', 1650.25, 15.75, 0.96, 2200000, 1100000000000, 1670.00, 1640.00, 1750.00, 1400.00
        WHERE NOT EXISTS (SELECT 1 FROM "Stock" WHERE symbol = 'HDFC');
        
        INSERT INTO "Stock" ("symbol", "name", "currentPrice", "change", "changePercent", "volume", "marketCap", "dayHigh", "dayLow", "yearHigh", "yearLow")
        SELECT 'ICICIBANK', 'ICICI Bank', 950.50, -8.25, -0.86, 1800000, 850000000000, 965.00, 945.00, 1050.00, 800.00
        WHERE NOT EXISTS (SELECT 1 FROM "Stock" WHERE symbol = 'ICICIBANK');
EOSQL

    echo "✓ Sample data inserted into '$db_name'."
}

# Function to verify database setup
verify_setup() {
    local db_name=$1
    echo "Verifying database setup for '$db_name'..."
    
    # Count tables
    local table_count=$(psql -U "$POSTGRES_USER" -d "$db_name" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    echo "✓ Found $table_count tables in '$db_name'."
    
    # Count stock records
    local stock_count=$(psql -U "$POSTGRES_USER" -d "$db_name" -tAc "SELECT COUNT(*) FROM \"Stock\";")
    echo "✓ Found $stock_count stock records in '$db_name'."
    
    # List all tables
    echo "Tables in '$db_name':"
    psql -U "$POSTGRES_USER" -d "$db_name" -c "\dt" | grep -E "^\s+(public\s+)?\w+\s+\|\s+table" || echo "No tables found or different format."
}

# Main execution
main() {
    echo "Starting database initialization process..."
    
    # Wait for PostgreSQL to be ready
    wait_for_postgres
    
    # Create databases
    echo "Creating required databases..."
    create_database_if_not_exists "simplehot_db"
    create_database_if_not_exists "metabase"
    
    # Test connections
    echo "Testing database connections..."
    test_database_connection "simplehot_db"
    test_database_connection "metabase"
    
    # Setup schema for main application database
    echo "Setting up application database schema..."
    setup_database_schema "simplehot_db"
    
    # Insert sample data
    echo "Inserting sample data..."
    insert_sample_data "simplehot_db"
    
    # Verify setup
    echo "Verifying database setup..."
    verify_setup "simplehot_db"
    
    echo "================================================"
    echo "✅ Database initialization completed successfully!"
    echo "✅ simplehot_db: Ready for application use"
    echo "✅ metabase: Ready for analytics"
    echo "Script completed at: $(date)"
    echo "================================================"
}

# Check if script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    main "$@"
fi