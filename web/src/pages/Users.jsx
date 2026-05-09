import { useEffect, useState, useCallback } from 'react';
import { adminApi } from '../api/adminApi';
import Badge, { roleBadge } from '../components/ui/Badge';
import Pagination from '../components/ui/Pagination';
import Modal from '../components/ui/Modal';
import { PageLoader } from '../components/ui/Spinner';
import toast from 'react-hot-toast';
import { format } from 'date-fns';

const ROLES   = ['', 'landowner', 'manager', 'worker', 'admin'];
const STATUSES = ['', 'active', 'inactive', 'unverified'];

export default function Users() {
  const [data,    setData]    = useState({ users: [], pagination: null });
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({ search: '', role: '', status: '', page: 1 });
  const [selected, setSelected] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  const fetchUsers = useCallback(async (f) => {
    setLoading(true);
    try {
      const res = await adminApi.listUsers({ ...f, limit: 15 });
      setData(res);
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchUsers(filters); }, [filters, fetchUsers]);

  const setFilter = (key, value) => setFilters((f) => ({ ...f, [key]: value, page: 1 }));

  const toggleStatus = async (user) => {
    setActionLoading(true);
    try {
      const updated = await adminApi.setUserStatus(user.id, !user.is_active);
      toast.success(`User ${updated.is_active ? 'activated' : 'deactivated'}`);
      setSelected((prev) => prev ? { ...prev, is_active: updated.is_active } : null);
      fetchUsers(filters);
    } catch (err) {
      toast.error(err.message);
    } finally {
      setActionLoading(false);
    }
  };

  const openDetail = async (id) => {
    try {
      const user = await adminApi.getUserById(id);
      setSelected(user);
    } catch (err) {
      toast.error(err.message);
    }
  };

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="card p-4 flex flex-wrap gap-3 items-center">
        <div className="flex-1 min-w-48 relative">
          <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search name, email, CNIC…"
            className="input pl-9"
            value={filters.search}
            onChange={(e) => setFilter('search', e.target.value)}
          />
        </div>
        <select
          className="input w-auto"
          value={filters.role}
          onChange={(e) => setFilter('role', e.target.value)}
        >
          <option value="">All Roles</option>
          {ROLES.filter(Boolean).map((r) => (
            <option key={r} value={r}>{r.charAt(0).toUpperCase() + r.slice(1)}</option>
          ))}
        </select>
        <select
          className="input w-auto"
          value={filters.status}
          onChange={(e) => setFilter('status', e.target.value)}
        >
          <option value="">All Status</option>
          {STATUSES.filter(Boolean).map((s) => (
            <option key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</option>
          ))}
        </select>
        {(filters.search || filters.role || filters.status) && (
          <button
            className="btn-ghost text-xs"
            onClick={() => setFilters({ search: '', role: '', status: '', page: 1 })}
          >
            Clear
          </button>
        )}
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">User</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider hidden md:table-cell">Role</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider hidden lg:table-cell">Joined</th>
                <th className="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                <tr><td colSpan={5} className="py-16 text-center"><PageLoader /></td></tr>
              ) : data.users.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-16 text-center text-gray-400">
                    <EmptyIcon className="w-10 h-10 mx-auto mb-2 text-gray-300" />
                    No users found
                  </td>
                </tr>
              ) : (
                data.users.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-semibold text-sm shrink-0">
                          {user.full_name?.[0]?.toUpperCase() ?? '?'}
                        </div>
                        <div className="min-w-0">
                          <p className="font-medium text-gray-900 truncate">{user.full_name}</p>
                          <p className="text-xs text-gray-400 truncate">{user.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      <Badge variant={roleBadge(user.role)}>{user.role}</Badge>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col gap-1">
                        <Badge variant={user.is_active ? 'green' : 'red'} dot>
                          {user.is_active ? 'Active' : 'Inactive'}
                        </Badge>
                        {!user.is_verified && <Badge variant="yellow">Unverified</Badge>}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-xs text-gray-400 hidden lg:table-cell">
                      {format(new Date(user.created_at), 'dd MMM yyyy')}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        className="btn-secondary text-xs py-1 px-3"
                        onClick={() => openDetail(user.id)}
                      >
                        View
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        {data.pagination && (
          <div className="px-4 border-t border-gray-200">
            <Pagination
              pagination={data.pagination}
              onPageChange={(p) => setFilters((f) => ({ ...f, page: p }))}
            />
          </div>
        )}
      </div>

      {/* User detail modal */}
      <Modal
        open={!!selected}
        onClose={() => setSelected(null)}
        title="User Details"
        size="md"
      >
        {selected && (
          <UserDetailPanel
            user={selected}
            onToggleStatus={toggleStatus}
            loading={actionLoading}
          />
        )}
      </Modal>
    </div>
  );
}

function UserDetailPanel({ user, onToggleStatus, loading }) {
  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center gap-4">
        <div className="w-14 h-14 rounded-2xl bg-primary-100 text-primary-700 flex items-center justify-center text-xl font-bold">
          {user.full_name?.[0]?.toUpperCase()}
        </div>
        <div>
          <p className="text-lg font-semibold text-gray-900">{user.full_name}</p>
          <p className="text-sm text-gray-500">{user.email}</p>
          <div className="flex gap-2 mt-1 flex-wrap">
            <Badge variant={roleBadge(user.role)}>{user.role}</Badge>
            <Badge variant={user.is_active ? 'green' : 'red'} dot>
              {user.is_active ? 'Active' : 'Inactive'}
            </Badge>
            <Badge variant={user.is_verified ? 'green' : 'yellow'}>
              {user.is_verified ? 'Verified' : 'Unverified'}
            </Badge>
          </div>
        </div>
      </div>

      {/* Info grid */}
      <div className="grid grid-cols-2 gap-3">
        {[
          { label: 'Phone',     value: user.phone    || '—' },
          { label: 'CNIC',      value: user.cnic     || '—' },
          { label: 'Joined',    value: format(new Date(user.created_at), 'dd MMM yyyy') },
          { label: 'Failed Attempts', value: user.failed_attempts ?? 0 },
          { label: 'Locked Until', value: user.locked_until ? format(new Date(user.locked_until), 'dd MMM yyyy HH:mm') : '—' },
          { label: 'User ID',   value: <span className="font-mono text-xs">{user.id.slice(0, 8)}…</span> },
        ].map(({ label, value }) => (
          <div key={label} className="bg-gray-50 rounded-lg px-3 py-2">
            <p className="text-xs text-gray-400 font-medium">{label}</p>
            <p className="text-sm text-gray-800 mt-0.5">{value}</p>
          </div>
        ))}
      </div>

      {/* Notification prefs */}
      {(user.push_alerts != null || user.email_digest != null) && (
        <div>
          <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Notification Preferences</p>
          <div className="flex gap-2 flex-wrap">
            <PrefChip label="Push"  on={user.push_alerts} />
            <PrefChip label="Email" on={user.email_digest} />
            <PrefChip label="SMS"   on={user.sms_alerts} />
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="pt-2 border-t border-gray-200">
        <button
          onClick={() => onToggleStatus(user)}
          disabled={loading}
          className={`btn w-full ${user.is_active ? 'btn-danger' : 'btn-primary'}`}
        >
          {loading
            ? 'Processing…'
            : user.is_active
              ? 'Deactivate Account'
              : 'Activate Account'}
        </button>
      </div>
    </div>
  );
}

function PrefChip({ label, on }) {
  return (
    <span className={`px-2.5 py-1 rounded-full text-xs font-medium border ${on ? 'bg-green-50 text-green-700 border-green-200' : 'bg-gray-50 text-gray-400 border-gray-200'}`}>
      {label}: {on ? 'On' : 'Off'}
    </span>
  );
}

function SearchIcon({ className }) {
  return <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>;
}
function EmptyIcon({ className }) {
  return <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}><path strokeLinecap="round" strokeLinejoin="round" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" /></svg>;
}