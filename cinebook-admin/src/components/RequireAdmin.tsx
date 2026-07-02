import { Navigate } from 'react-router-dom';
import { useAuth } from '../lib/auth';

export function RequireAdmin({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth();
  if (isLoading) return <div className="loading">Loading…</div>;
  if (!user || user.role !== 'ADMIN') return <Navigate to="/login" replace />;
  return <>{children}</>;
}
