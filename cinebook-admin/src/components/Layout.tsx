import { NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../lib/auth';

const NAV_ITEMS = [
  { to: '/users', label: 'Users', icon: '👥' },
  { to: '/movies', label: 'Movies', icon: '🎬' },
  { to: '/theatres', label: 'Theatres', icon: '🏛️' },
  { to: '/screens', label: 'Screens', icon: '🖥️' },
  { to: '/shows', label: 'Shows', icon: '🎭' },
  { to: '/genres', label: 'Genres', icon: '🏷️' },
  { to: '/reports', label: 'Reports', icon: '📊' },
  { to: '/activity', label: 'Activity Log', icon: '📋' },
];

export default function Layout() {
  const { user, logout } = useAuth();

  return (
    <div className="admin-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span className="brand-icon">🎬</span>
          <span className="brand-text">CineBook</span>
        </div>
        <nav className="sidebar-nav">
          {NAV_ITEMS.map(({ to, label, icon }) => (
            <NavLink key={to} to={to} className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
              <span className="nav-icon">{icon}</span>
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>
      </aside>
      <main className="main-content">
        <header className="top-bar">
          <div />
          <div className="user-info">
            <span>{user?.name || user?.phone}</span>
            <button className="logout-btn" onClick={logout}>Logout</button>
          </div>
        </header>
        <div className="page-content">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
