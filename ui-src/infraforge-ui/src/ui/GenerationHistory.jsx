export default function GenerationHistory({ history = [] }) {
  const historyList = Array.isArray(history) ? history : [];

  if (!historyList.length) {
    return (
      <div className="p-2 text-sm text-neutral-500">
        No previous generations
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {historyList.map((h) => (
        <div
          key={h.id}
          className="p-2 rounded bg-neutral-900 text-sm"
        >
          <div className="text-neutral-300">
            Job {h.id.slice(0, 8)}
          </div>
          <div className="text-neutral-500 text-xs">
            {h.status}
          </div>
        </div>
      ))}
    </div>
  );
}
