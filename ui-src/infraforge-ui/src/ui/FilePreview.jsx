import { invoke } from "@tauri-apps/api/core";
import { useEffect, useState } from "react";

export default function FilePreview({ file }) {
  const [content, setContent] = useState("");

  useEffect(() => {
    if (!file) return;

    invoke("read_file", { path: file.path })
      .then(setContent)
      .catch(() => setContent("Failed to read file"));
  }, [file]);

  if (!file) {
    return (
      <div className="text-neutral-500 text-sm">
        Select a file to preview
      </div>
    );
  }

  return (
    <pre className="bg-black text-green-400 text-xs p-4 rounded overflow-auto h-full">
      {content}
    </pre>
  );
}
