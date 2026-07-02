import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth.js';
import { connectRedis } from './redis.js';
import { errorHandler } from './middlewares/errorMiddleware.js';

const app = express();

app.use(cors());
app.use(express.json());

app.use('/auth', authRoutes);

app.use(errorHandler);

const PORT = process.env.PORT || 3000;

export const startServer = async () => {
  await connectRedis();
  app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
  });
};

// @ts-ignore
if (import.meta.url === `file://${process.argv[1]}`) {
  startServer();
}

export default app;
