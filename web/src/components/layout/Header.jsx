import { useLocation } from 'react-router-dom';

const TITLES = {
  '/':        'Dashboard',
  '/users':   'User Management',
  '/profile': 'My Profile',
};

export default function Header({ onMenuClick }) {
  const { pathname } = useLocation();
  const title = Object.entries(TITLES).findLast(([k]) => pathname.startsWith(k))?.[1] ?? 'Admin';

  return (
    <header className="sticky top-0 z-10 bg-white border-b border-gray-200 px-4 sm:px-6 py-3 flex items-center gap-4">
      <button
        onClick={onMenuClick}
        className="lg:hidden p-2 -ml-2 rounded-lg text-gray-500 hover:bg-gray-100 transition"
        aria-label="Open menu"
      >
        <MenuIcon className="w-5 h-5" />
      </button>

      <h1 className="text-lg font-semibold text-gray-900">{title}</h1>

      <div className="ml-auto flex items-center gap-2">
        <span className="hidden sm:inline-flex items-center gap-1.5 text-xs bg-primary-50 text-primary-700 border border-primary-200 px-2.5 py-1 rounded-full font-medium">
          <span className="w-1.5 h-1.5 bg-primary-500 rounded-full animate-pulse" />
          Admin
        </span>
      </div>
    </header>
  );
}

function MenuIcon({ className }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16" />
    </svg>
  );
}