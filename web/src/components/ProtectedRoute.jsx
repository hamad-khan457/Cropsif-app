import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { PageLoader } from './ui/Spinner';

export default function ProtectedRoute() {
  const { user, loading } = useAuth();
  if (loading) return <PageLoader />;
  return user ? <Outlet /> : <Navigate to="/login" replace />;
}