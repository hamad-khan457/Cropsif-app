import { NavLink } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const NAV = [
  { to: '/',        icon: GridIcon,     label: 'Dashboard' },
  { to: '/users',   icon: UsersIcon,    label: 'Users' },
  { to: '/profile', icon: ProfileIcon,  label: 'My Profile' },
];

export default function Sidebar({ open, onClose }) {
  const { user, logout } = useAuth();

  return (
    <>
      {/* Mobile overlay */}
      {open && (
        <div
          className="fixed inset-0 z-20 bg-black/40 lg:hidden"
          onClick={onClose}
        />
      )}

      <aside
        className={`
          fixed inset-y-0 left-0 z-30 flex flex-col w-64 bg-primary-900 text-white
          transform transition-transform duration-200 ease-in-out
          lg:relative lg:translate-x-0 lg:z-auto
          ${open ? 'translate-x-0' : '-translate-x-full'}
        `}
      >
        {/* Logo */}
        <div className="flex items-center gap-3 px-6 py-5 border-b border-primary-800">
          <div className="w-9 h-9 bg-white/10 rounded-xl flex items-center justify-center">
            <LeafIcon className="w-5 h-5 text-primary-300" />
          </div>
          <div>
            <p className="font-bold text-base leading-tight">Cropsify</p>
            <p className="text-primary-400 text-xs">Admin Panel</p>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
          {NAV.map(({ to, icon: Icon, label }) => (
            <NavLink
              key={to}
              to={to}
              end={to === '/'}
              onClick={onClose}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-white/15 text-white'
                    : 'text-primary-300 hover:bg-white/10 hover:text-white'
                }`
              }
            >
              <Icon className="w-5 h-5 shrink-0" />
              {label}
            </NavLink>
          ))}
        </nav>

        {/* User footer */}
        <div className="px-4 py-4 border-t border-primary-800">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center font-bold text-sm">
              {user?.full_name?.[0]?.toUpperCase() ?? 'A'}
            </div>
            <div className="min-w-0">
              <p className="text-sm font-medium truncate">{user?.full_name ?? 'Admin'}</p>
              <p className="text-xs text-primary-400 truncate">{user?.email}</p>
            </div>
          </div>
          <button
            onClick={logout}
            className="w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-primary-300 hover:bg-white/10 hover:text-white transition-colors"
          >
            <LogoutIcon className="w-4 h-4" />
            Sign Out
          </button>
        </div>
      </aside>
    </>
  );
}

// ── Inline SVG icons ──────────────────────────────────────────────────────────
function GridIcon({ className }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z" />
    </svg>
  );
}
function UsersIcon({ className }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.768-.231-1.48-.63-2.073M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.768.231-1.48.63-2.073m0 0A5.002 5.002 0 0112 11a5 5 0 014.37 2.57M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
    </svg>
  );
}
function ProfileIcon({ className }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
    </svg>
  );
}
function LeafIcon({ className }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 3C7 3 3 7 3 12c0 4.5 3 8.5 7.5 9.5C12 18 14 14 14 10c0 4 2 8 4.5 11C21 19 21 12 21 9c0-3.5-3-6-9-6z" />
    </svg>
  );
}
function LogoutIcon({ className }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h6a2 2 0 012 2v1" />
    </svg>
  );
}