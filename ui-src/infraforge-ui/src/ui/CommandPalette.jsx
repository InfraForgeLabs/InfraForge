export default function CommandPalette({ onClose }) {
  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div className="w-[420px] bg-neutral-900 border border-neutral-700 rounded-lg shadow-xl">
        <div className="px-4 py-3 border-b border-neutral-700 text-sm text-neutral-400">
          Command Palette
        </div>

        <ul className="divide-y divide-neutral-800 text-sm">
          <Item label="Start Agent" />
          <Item label="Stop Agent" />
          <Item label="Generate Infrastructure" />
          <Item label="Open Logs" />
        </ul>

        <div className="px-4 py-2 text-xs text-neutral-500">
          Press Esc to close
        </div>
      </div>
    </div>
  );
}

function Item({ label }) {
  return (
    <li className="px-4 py-3 hover:bg-neutral-800 cursor-pointer">
      {label}
    </li>
  );
}
