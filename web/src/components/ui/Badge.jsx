const VARIANTS = {
  green:  'bg-green-100 text-green-700 border-green-200',
  red:    'bg-red-100 text-red-700 border-red-200',
  yellow: 'bg-yellow-100 text-yellow-700 border-yellow-200',
  blue:   'bg-blue-100 text-blue-700 border-blue-200',
  purple: 'bg-purple-100 text-purple-700 border-purple-200',
  gray:   'bg-gray-100 text-gray-600 border-gray-200',
  amber:  'bg-amber-100 text-amber-700 border-amber-200',
};

export default function Badge({ children, variant = 'gray', dot = false }) {
  return (
    <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium border ${VARIANTS[variant]}`}>
      {dot && <span className={`w-1.5 h-1.5 rounded-full ${dotColor(variant)}`} />}
      {children}
    </span>
  );
}

function dotColor(v) {
  const map = {
    green: 'bg-green-500', red: 'bg-red-500', yellow: 'bg-yellow-500',
    blue: 'bg-blue-500',   purple: 'bg-purple-500', gray: 'bg-gray-400', amber: 'bg-amber-500',
  };
  return map[v] ?? 'bg-gray-400';
}

// Role → badge variant
export function roleBadge(role) {
  return { landowner: 'green', manager: 'blue', worker: 'amber', admin: 'purple' }[role] ?? 'gray';
}