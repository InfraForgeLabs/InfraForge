export default function FileTree({ files, onSelect }) {
  return (
    <ul className="font-mono text-sm text-neutral-300 space-y-1">
      {files.map((f) => (
        <li
          key={f.path}
          className="cursor-pointer hover:text-white"
          onClick={() => onSelect(f)}
        >
          {f.type === "dir" ? "📁" : "📄"} {f.name}
        </li>
      ))}
    </ul>
  );
}
