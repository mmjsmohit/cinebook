import dotenv from 'dotenv';
dotenv.config();

const isDev = process.env.NODE_ENV !== 'production';

if (!process.env.JWT_SECRET && !isDev) {
  throw new Error('JWT_SECRET environment variable is required in non-development environments');
}

export const JWT_SECRET = process.env.JWT_SECRET || 'secret';
