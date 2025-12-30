/*
  DiffPanel
  - Browser preview: disabled
  - Desktop runtime: file diff via agent
*/

export default function DiffPanel({ templatePath, outputPath }) {
  // 🚫 Browser preview — no filesystem
  if (!window.__TAURI__) {
    return (
      <div className="flex flex-1 items-center justify-center text-neutral-500">
        Diff preview unavailable (agent not running)
      </div>
    );
  }

  // Lazy-load agent-only logic
  const [diff, setDiff] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadDiff() {
      try {
        const { invoke } = await import("@tauri-apps/api/core");
        const result = await invoke("diff_files_ui", {
          template: templatePath,
          output: outputPath
        });
        if (!cancelled) setDiff(result);
      } catch (err) {
        console.error("[InfraForge] Diff failed:", err);
      }
    }

    loadDiff();
    return () => (cancelled = true);
  }, [templatePath, outputPath]);

  return (
    <pre className="flex-1 overflow-auto p-2 text-xs font-mono text-neutral-300">
      {diff || "No changes"}
    </pre>
  );
}
