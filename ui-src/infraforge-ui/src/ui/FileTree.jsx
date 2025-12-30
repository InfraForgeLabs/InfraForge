export default function FileTree({ files = [] }) {
  const fileList = Array.isArray(files) ? files : [];

  if (!fileList.length) {
    return (
      <div className="p-2 text-sm text-neutral-500">
        No files generated
      </div>
    );
  }

  return (
    <ul className="text-sm space-y-1">
      {fileList.map((f) => (
        <li key={f} className="text-neutral-300">
          {f}
        </li>
      ))}
    </ul>
  );
}
