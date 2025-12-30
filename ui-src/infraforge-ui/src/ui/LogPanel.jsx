export default function LogPanel({ logs = [] }) {
  const logList = Array.isArray(logs) ? logs : [];

  if (!logList.length) {
    return (
      <div className="flex-1 p-4 text-sm text-neutral-500">
        No logs yet
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-auto p-2 font-mono text-xs">
      {logList.map((l, i) => (
        <div key={i} className="text-neutral-300">
          {l.message ?? String(l)}
        </div>
      ))}
    </div>
  );
}
