import { createContext, useContext, useState, useEffect, type ReactNode } from 'react';
import { api, setTokens, clearTokens, getStoredRefreshToken } from './api';
import axios from 'axios';

interface User { id: string; role: string; phone: string; name?: string; }
interface AuthCtx { 
  user: User | null; 
  isLoading: boolean; 
  login: (phone: string, otp: string) => Promise<void>; 
  logout: () => void; 
  requestOtp: (phone: string) => Promise<void>; 
}

const AuthContext = createContext<AuthCtx | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const rt = getStoredRefreshToken();
    if (rt) {
      const base = import.meta.env.VITE_API_URL || 'http://localhost:3000';
      axios.post(`${base}/auth/refresh`, { refreshToken: rt })
        .then((res) => {
          setTokens(res.data.accessToken, res.data.refreshToken);
          setUser(res.data.user);
        })
        .catch(() => clearTokens())
        .finally(() => setIsLoading(false));
    } else {
      setIsLoading(false);
    }
  }, []);

  const requestOtp = async (phone: string) => {
    await api.post('/auth/request-otp', { phone });
  };

  const login = async (phone: string, otp: string) => {
    const res = await api.post('/auth/verify-otp', { phone, code: otp });
    if (res.data.user.role !== 'ADMIN') {
      throw new Error('Access denied: ADMIN role required');
    }
    setTokens(res.data.accessToken, res.data.refreshToken);
    setUser(res.data.user);
  };

  const logout = () => {
    clearTokens();
    setUser(null);
  };

  return <AuthContext.Provider value={{ user, isLoading, login, logout, requestOtp }}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
