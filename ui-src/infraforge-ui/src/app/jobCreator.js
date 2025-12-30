import { v4 as uuidv4 } from "uuid";

export function createJob({ stack, workspace, outputDir }) {
  const job = {
    id: uuidv4(),
    source: "browser",
    workspace,
    stack,
    status: "pending",
    started_at: new Date().toISOString(),
    ended_at: null,
    output_dir: outputDir,
    last_log: null
  };

  // Assume FS access already exists (Electron/Tauri file bridge)
  window.__infraforge_write_job(job);

  window.location.href = `infraforge://generation?job_id=${job.id}`;
}

