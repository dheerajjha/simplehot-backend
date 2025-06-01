FROM node:18-alpine

WORKDIR /app

# Install OpenSSL
RUN apk add --no-cache openssl
RUN ln -s /usr/lib/libssl.so /usr/lib/libssl.so.1.1 && \
    ln -s /usr/lib/libcrypto.so /usr/lib/libcrypto.so.1.1

COPY package*.json ./

RUN npm install

COPY . .

RUN npx prisma generate

EXPOSE 5001

CMD ["npm", "start"] 