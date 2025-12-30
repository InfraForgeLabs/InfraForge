import { invoke } from "@tauri-apps/api/core";
import { useEffect, useState } from "react";

export default function DiffPanel({ templatePath, outputPath }) {
  const [diff, setDiff] = useState("");

  useEffect(() => {
    if (!templatePath || !outputPath) return;

    invoke("diff_files", {
      template: templatePath,
      output: outputPath,
    })
      .then(setDiff)
      .catch(() => setDiff("Failed to generate diff"));
  }, [templatePath, outputPath]);

  if (!templatePath || !outputPath) {
    return (
      <div className="text-neutral-500 text-sm">
        Select files to compare
      </div>
    );
  }

  return (
    <pre className="bg-black text-xs text-neutral-200 p-4 overflow-auto h-full">
      {diff}
    </pre>
  );
}

