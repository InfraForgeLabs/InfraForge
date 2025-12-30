export default function WorkspaceSwitcher({ workspace, setWorkspace }) {
  return (
    <div className="flex items-center gap-2 text-sm">
      <span className="text-neutral-400">Workspace</span>
      <select
        value={workspace}
        onChange={(e) => {
          localStorage.setItem("infraforgeWorkspace", e.target.value);
          setWorkspace(e.target.value);
        }}
        className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1"
      >
        <option value="default">default</option>
        <option value="lab">lab</option>
        <option value="prod-sim">prod-sim</option>
      </select>
    </div>
  );
}

