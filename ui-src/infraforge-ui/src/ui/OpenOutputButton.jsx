import { invoke } from "@tauri-apps/api/core";

export default function OpenOutputButton({ path }) {
  if (!path) return null;

  return (
    <button
      onClick={() => invoke("open_output_dir", { path })}
      className="px-3 py-1 text-xs rounded bg-neutral-800 hover:bg-neutral-700"
    >
      Open Output Directory
    </button>
  );
}
