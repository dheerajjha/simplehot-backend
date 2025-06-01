#!/bin/bash

set -e
set -u

echo "Creating user_db database..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE user_db;
    GRANT ALL PRIVILEGES ON DATABASE user_db TO $POSTGRES_USER;
EOSQL
echo "Database user_db created successfully" 