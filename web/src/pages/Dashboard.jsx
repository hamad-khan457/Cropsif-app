import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { adminApi } from '../api/adminApi';
import { PageLoader } from '../components/ui/Spinner';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts';

const ROLE_COLORS = { landowners: '#15803d', managers: '#2563eb', workers: '#d97706', admins: '#7c3aed' };

export default function Dashboard() {
  const [stats,   setStats]   = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminApi.getStats()
      .then(setStats)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <PageLoader />;
  if (!stats)  return <p className="text-gray-500">Failed to load stats.</p>;

  const pieData = [
    { name: 'Landowners', value: Number(stats.landowners) },
    { name: 'Managers',   value: Number(stats.managers) },
    { name: 'Workers',    value: Number(stats.workers) },
    { name: 'Admins',     value: Number(stats.admins) },
  ].filter((d) => d.value > 0);

  return (
    <div className="space-y-6">
      {/* KPI cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="Total Users"
          value={stats.total}
          icon={<UsersIcon />}
          color="text-primary-700 bg-primary-50"
        />
        <StatCard
          label="Active"
          value={stats.active}
          icon={<CheckIcon />}
          color="text-green-700 bg-green-50"
        />
        <StatCard
          label="Inactive"
          value={stats.inactive}
          icon={<BanIcon />}
          color="text-red-600 bg-red-50"
        />
        <StatCard
          label="New This Week"
          value={stats.new_this_week}
          icon={<TrendIcon />}
          color="text-blue-700 bg-blue-50"
        />
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        {/* Role distribution pie */}
        <div className="card p-6">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">Users by Role</h2>
          {pieData.length > 0 ? (
            <ResponsiveContainer width="100%" height={240}>
              <PieChart>
                <Pie data={pieData} dataKey="value" cx="50%" cy="50%" outerRadius={90} label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`} labelLine={false}>
                  {pieData.map((entry) => (
                    <Cell key={entry.name} fill={ROLE_COLORS[entry.name.toLowerCase()] ?? '#94a3b8'} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <p className="text-gray-400 text-sm text-center py-10">No data yet</p>
          )}
        </div>

        {/* Breakdown table */}
        <div className="card p-6">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">Account Breakdown</h2>
          <div className="space-y-3">
            {[
              { label: 'Landowners',  value: stats.landowners,  color: 'bg-green-500' },
              { label: 'Managers',    value: stats.managers,    color: 'bg-blue-500' },
              { label: 'Workers',     value: stats.workers,     color: 'bg-amber-500' },
              { label: 'Admins',      value: stats.admins,      color: 'bg-purple-500' },
              { label: 'Unverified',  value: stats.unverified,  color: 'bg-gray-400' },
            ].map(({ label, value, color }) => {
              const pct = stats.total > 0 ? Math.round((Number(value) / Number(stats.total)) * 100) : 0;
              return (
                <div key={label}>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-gray-600">{label}</span>
                    <span className="font-medium text-gray-800">{value}</span>
                  </div>
                  <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                    <div className={`h-full ${color} rounded-full`} style={{ width: `${pct}%` }} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Quick link */}
      <div className="card p-5 flex items-center justify-between">
        <div>
          <p className="font-semibold text-gray-800">Manage Users</p>
          <p className="text-sm text-gray-500">View, search, activate or deactivate accounts</p>
        </div>
        <Link to="/users" className="btn-primary whitespace-nowrap">Go to Users →</Link>
      </div>
    </div>
  );
}

function StatCard({ label, value, icon, color }) {
  return (
    <div className="card p-5 flex items-center gap-4">
      <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${color}`}>
        {icon}
      </div>
      <div>
        <p className="text-2xl font-bold text-gray-900">{Number(value).toLocaleString()}</p>
        <p className="text-xs text-gray-500 font-medium">{label}</p>
      </div>
    </div>
  );
}

function UsersIcon() { return <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.768-.231-1.48-.63-2.073M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.768.231-1.48.63-2.073m0 0A5.002 5.002 0 0112 11a5 5 0 014.37 2.57M15 7a3 3 0 11-6 0 3 3 0 016 0z" /></svg>; }
function CheckIcon() { return <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>; }
function BanIcon()   { return <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" /></svg>; }
function TrendIcon() { return <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" /></svg>; }