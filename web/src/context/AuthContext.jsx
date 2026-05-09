import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { authApi } from '../api/authApi';
import { tokenStorage } from '../utils/tokenStorage';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user,    setUser]    = useState(null);
  const [loading, setLoading] = useState(true); // initial auth check
  const [error,   setError]   = useState(null);

  // Rehydrate session on mount
  useEffect(() => {
    const token = tokenStorage.getAccess() || tokenStorage.getRefresh();
    if (!token) { setLoading(false); return; }
    authApi.me()
      .then((u) => {
        if (u.role !== 'admin') {
          tokenStorage.clear();
          setLoading(false);
          return;
        }
        setUser(u);
      })
      .catch(() => tokenStorage.clear())
      .finally(() => setLoading(false));
  }, []);

  const login = useCallback(async (email, password) => {
    setError(null);
    const u = await authApi.login(email, password);
    if (u.role !== 'admin') {
      tokenStorage.clear();
      throw new Error('Access denied: admin accounts only');
    }
    setUser(u);
    return u;
  }, []);

  const logout = useCallback(async () => {
    await authApi.logout();
    setUser(null);
  }, []);

  const refreshUser = useCallback(async () => {
    const u = await authApi.me();
    setUser(u);
    return u;
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading, error, login, logout, refreshUser, setError }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
};