FROM node:18-alpine

WORKDIR /app

# Copy all code
COPY . .

# Skip npm install - will use mounted node_modules from host
EXPOSE 5050

CMD ["npm", "start"] 