FROM node:18-alpine

# Install OpenSSL for Prisma
RUN apk add --no-cache openssl

# Create symbolic link for libssl.so.1.1
RUN ln -s /usr/lib/libssl.so /usr/lib/libssl.so.1.1 && \
    ln -s /usr/lib/libcrypto.so /usr/lib/libcrypto.so.1.1

WORKDIR /app

# Copy all code
COPY . .

# Skip npm install - will use mounted node_modules from host
EXPOSE 5002

# Generate Prisma client at runtime and start
CMD ["sh", "-c", "npx prisma generate && npm start"]