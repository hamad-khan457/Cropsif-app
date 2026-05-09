export default function Pagination({ pagination, onPageChange }) {
  if (!pagination || pagination.pages <= 1) return null;
  const { page, pages, total, limit } = pagination;

  const from = (page - 1) * limit + 1;
  const to   = Math.min(page * limit, total);

  return (
    <div className="flex items-center justify-between px-1 py-3">
      <p className="text-sm text-gray-500">
        Showing <span className="font-medium">{from}–{to}</span> of{' '}
        <span className="font-medium">{total}</span>
      </p>
      <div className="flex items-center gap-1">
        <PagBtn onClick={() => onPageChange(page - 1)} disabled={page <= 1}>‹ Prev</PagBtn>
        {pageNumbers(page, pages).map((p, i) =>
          p === '…' ? (
            <span key={`ellipsis-${i}`} className="px-2 text-gray-400">…</span>
          ) : (
            <PagBtn key={p} onClick={() => onPageChange(p)} active={p === page}>
              {p}
            </PagBtn>
          ),
        )}
        <PagBtn onClick={() => onPageChange(page + 1)} disabled={page >= pages}>Next ›</PagBtn>
      </div>
    </div>
  );
}

function PagBtn({ children, onClick, disabled, active }) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`px-3 py-1.5 rounded-lg text-sm font-medium transition disabled:opacity-40 disabled:cursor-not-allowed ${
        active
          ? 'bg-primary-700 text-white'
          : 'bg-white border border-gray-300 text-gray-700 hover:bg-gray-50'
      }`}
    >
      {children}
    </button>
  );
}

function pageNumbers(current, total) {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  if (current <= 4) return [1, 2, 3, 4, 5, '…', total];
  if (current >= total - 3) return [1, '…', total - 4, total - 3, total - 2, total - 1, total];
  return [1, '…', current - 1, current, current + 1, '…', total];
}