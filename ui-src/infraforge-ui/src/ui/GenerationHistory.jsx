export default function GenerationHistory({ history }) {
  if (history.length === 0) {
    return (
      <div className="text-neutral-500 text-sm">
        No generations yet
      </div>
    );
  }

  return (
    <ul className="space-y-2 text-sm">
      {history.map((h) => (
        <li
          key={h.id}
          className="border border-neutral-800 rounded p-2"
        >
          <div className="font-semibold">{h.stack}</div>
          <div className="text-neutral-500">
            {new Date(h.startedAt).toLocaleString()}
          </div>
          <div className="text-neutral-400 text-xs">
            {h.outputDir}
          </div>
        </li>
      ))}
    </ul>
  );
}
