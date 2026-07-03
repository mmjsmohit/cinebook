import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from './lib/auth';
import { RequireAdmin } from './components/RequireAdmin';
import Layout from './components/Layout';
import LoginPage from './pages/LoginPage';

// Lazy-loaded pages
import UsersPage from './pages/UsersPage';
import MoviesPage from './pages/MoviesPage';
import TheatresPage from './pages/TheatresPage';
import ScreensPage from './pages/ScreensPage';
import ShowsPage from './pages/ShowsPage';
import ReportsPage from './pages/ReportsPage';
import ActivityPage from './pages/ActivityPage';
import GenresPage from './pages/GenresPage';

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, retry: 1 } },
});

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<RequireAdmin><Layout /></RequireAdmin>}>
              <Route path="/users" element={<UsersPage />} />
              <Route path="/movies" element={<MoviesPage />} />
              <Route path="/theatres" element={<TheatresPage />} />
              <Route path="/screens" element={<ScreensPage />} />
              <Route path="/shows" element={<ShowsPage />} />
              <Route path="/genres" element={<GenresPage />} />
              <Route path="/reports" element={<ReportsPage />} />
              <Route path="/activity" element={<ActivityPage />} />
              <Route path="/" element={<Navigate to="/users" replace />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}
