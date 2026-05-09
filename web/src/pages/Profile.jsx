import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { authApi } from '../api/authApi';
import toast from 'react-hot-toast';
import Badge, { roleBadge } from '../components/ui/Badge';
import { format } from 'date-fns';

export default function Profile() {
  const { user, refreshUser } = useAuth();
  const [tab, setTab] = useState('info'); // 'info' | 'password'

  return (
    <div className="max-w-2xl space-y-6">
      {/* Profile header card */}
      <div className="card p-6 flex items-center gap-5">
        <div className="w-16 h-16 rounded-2xl bg-primary-100 text-primary-700 flex items-center justify-center text-2xl font-bold shrink-0">
          {user?.full_name?.[0]?.toUpperCase() ?? 'A'}
        </div>
        <div>
          <p className="text-xl font-semibold text-gray-900">{user?.full_name}</p>
          <p className="text-sm text-gray-500">{user?.email}</p>
          <div className="flex gap-2 mt-2">
            <Badge variant={roleBadge(user?.role)}>{user?.role}</Badge>
            <Badge variant={user?.is_verified ? 'green' : 'yellow'}>
              {user?.is_verified ? 'Verified' : 'Unverified'}
            </Badge>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 bg-gray-100 rounded-xl p-1 w-fit">
        {[['info', 'Account Info'], ['password', 'Change Password']].map(([key, label]) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all ${
              tab === key ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'info'     && <InfoTab user={user} onRefresh={refreshUser} />}
      {tab === 'password' && <PasswordTab />}
    </div>
  );
}

function InfoTab({ user, onRefresh }) {
  const [form, setForm]       = useState({ fullName: user?.full_name ?? '', phone: user?.phone ?? '' });
  const [loading, setLoading] = useState(false);

  const handleSave = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await authApi.updateProfile({
        fullName: form.fullName.trim() || undefined,
        phone:    form.phone.trim()    || undefined,
      });
      await onRefresh();
      toast.success('Profile updated');
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card p-6 space-y-6">
      {/* Read-only info */}
      <div className="grid sm:grid-cols-2 gap-4">
        {[
          { label: 'CNIC',   value: user?.cnic    || '—' },
          { label: 'Phone',  value: user?.phone   || '—' },
          { label: 'Joined', value: user?.created_at ? format(new Date(user.created_at), 'dd MMM yyyy') : '—' },
          { label: 'Status', value: user?.is_active ? 'Active' : 'Inactive' },
        ].map(({ label, value }) => (
          <div key={label}>
            <p className="label">{label}</p>
            <p className="text-sm text-gray-800 bg-gray-50 rounded-lg px-3 py-2">{value}</p>
          </div>
        ))}
      </div>

      <hr className="border-gray-200" />

      {/* Editable fields */}
      <form onSubmit={handleSave} className="space-y-4">
        <h3 className="text-sm font-semibold text-gray-700">Edit Details</h3>
        <div>
          <label className="label">Full Name</label>
          <input
            className="input"
            value={form.fullName}
            onChange={(e) => setForm((f) => ({ ...f, fullName: e.target.value }))}
            minLength={2}
            maxLength={100}
          />
        </div>
        <div>
          <label className="label">Phone Number</label>
          <input
            className="input"
            placeholder="03001234567"
            value={form.phone}
            onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
          />
          <p className="text-xs text-gray-400 mt-1">Format: 03XXXXXXXXX or +923XXXXXXXXX</p>
        </div>
        <button type="submit" disabled={loading} className="btn-primary">
          {loading ? 'Saving…' : 'Save Changes'}
        </button>
      </form>
    </div>
  );
}

function PasswordTab() {
  const [form, setForm] = useState({ current: '', next: '', confirm: '' });
  const [loading, setLoading] = useState(false);

  const handleSave = async (e) => {
    e.preventDefault();
    if (form.next !== form.confirm) { toast.error('Passwords do not match'); return; }
    if (form.next.length < 8)       { toast.error('Password must be at least 8 characters'); return; }
    if (!/[A-Z]/.test(form.next))   { toast.error('Password must contain an uppercase letter'); return; }
    if (!/[0-9]/.test(form.next))   { toast.error('Password must contain a number'); return; }

    setLoading(true);
    try {
      await authApi.changePassword(form.current, form.next);
      toast.success('Password changed successfully');
      setForm({ current: '', next: '', confirm: '' });
    } catch (err) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card p-6">
      <p className="text-sm text-gray-500 mb-5">
        New password must be at least 8 characters with one uppercase letter and one number.
      </p>
      <form onSubmit={handleSave} className="space-y-4">
        {[
          { key: 'current', label: 'Current Password' },
          { key: 'next',    label: 'New Password' },
          { key: 'confirm', label: 'Confirm New Password' },
        ].map(({ key, label }) => (
          <div key={key}>
            <label className="label">{label}</label>
            <input
              type="password"
              required
              className="input"
              value={form[key]}
              onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))}
            />
          </div>
        ))}
        <button type="submit" disabled={loading} className="btn-primary mt-2">
          {loading ? 'Changing…' : 'Change Password'}
        </button>
      </form>
    </div>
  );
}