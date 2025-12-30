export default function LogPanel({ logs }) {
  return (
    <div className="bg-black text-xs font-mono p-4 overflow-auto h-full">
      {logs.length === 0 && (
        <div className="text-neutral-500">Waiting for logs…</div>
      )}

      {logs.map((l, i) => (
        <div
          key={i}
          className={
            l.level === "error"
              ? "text-red-400"
              : l.level === "warn"
              ? "text-yellow-400"
              : "text-green-400"
          }
        >
          {l.text}
        </div>
      ))}
    </div>
  );
}
