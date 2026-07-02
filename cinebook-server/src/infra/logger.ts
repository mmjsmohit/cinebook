import { AsyncLocalStorage } from 'node:async_hooks';

interface LogContext {
  correlationId: string;
}

export const als = new AsyncLocalStorage<LogContext>();

type LogLevel = 'info' | 'warn' | 'error' | 'debug';

function log(level: LogLevel, message: string, meta?: Record<string, unknown>) {
  const ctx = als.getStore();
  const entry = {
    ts: new Date().toISOString(),
    level,
    correlationId: ctx?.correlationId ?? 'no-context',
    message,
    ...meta,
  };
  const line = JSON.stringify(entry);
  if (level === 'error') {
    console.error(line);
  } else {
    console.log(line);
  }
}

export const logger = {
  info: (message: string, meta?: Record<string, unknown>) => log('info', message, meta),
  warn: (message: string, meta?: Record<string, unknown>) => log('warn', message, meta),
  error: (message: string, meta?: Record<string, unknown>) => log('error', message, meta),
  debug: (message: string, meta?: Record<string, unknown>) => log('debug', message, meta),
};
