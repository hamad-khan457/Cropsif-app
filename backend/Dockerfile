FROM node:20-alpine

WORKDIR /app

# Install dependencies first (layer cache)
COPY package*.json ./
RUN npm install --omit=dev

# Copy source
COPY . .

EXPOSE 5000

# Run migrations, seed admin, then start server
CMD ["sh", "-c", "node src/config/migrate.js && node seed-admin.js && node server.js"]