import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import toast from 'react-hot-toast';

export default function Login() {
  const { login } = useAuth();
  const navigate   = useNavigate();
  const [form, setForm]       = useState({ email: '', password: '' });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await login(form.email.trim(), form.password);
      navigate('/', { replace: true });
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Brand */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-white/15 rounded-2xl mb-4">
            <LeafIcon className="w-9 h-9 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white">Cropsify</h1>
          <p className="text-primary-300 mt-1 text-sm">Administrator Portal</p>
        </div>

        {/* Card */}
        <div className="bg-white rounded-2xl shadow-2xl p-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-1">Welcome back</h2>
          <p className="text-sm text-gray-500 mb-6">Sign in to your admin account</p>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="label">Email Address</label>
              <input
                type="email"
                required
                autoFocus
                placeholder="admin@cropsify.pk"
                className="input"
                value={form.email}
                onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
              />
            </div>

            <div>
              <label className="label">Password</label>
              <input
                type="password"
                required
                placeholder="••••••••"
                className="input"
                value={form.password}
                onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="btn-primary w-full mt-2 py-2.5"
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/>
                  </svg>
                  Signing in…
                </span>
              ) : 'Sign In'}
            </button>
          </form>

          <p className="mt-6 text-center text-xs text-gray-400">
            This portal is restricted to admin accounts only.
          </p>
        </div>

        <p className="text-center text-primary-400 text-xs mt-6">
          Cropsify v1.0 · Module 1
        </p>
      </div>
    </div>
  );
}

function LeafIcon({ className }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round"
        d="M12 3C7 3 3 7 3 12c0 4.5 3 8.5 7.5 9.5C12 18 14 14 14 10c0 4 2 8 4.5 11C21 19 21 12 21 9c0-3.5-3-6-9-6z" />
    </svg>
  );
}