require('dotenv').config();
const app = require('./src/app');
const { testConnection } = require('./src/config/database');

const PORT = process.env.PORT || 3000;

async function bootstrap() {
  await testConnection();
  app.listen(PORT, () => {
    console.log(`Cropsify API running on port ${PORT} [${process.env.NODE_ENV}]`);
  });
}

bootstrap();