import { useState, useEffect } from "react";
import { v4 as uuidv4 } from "uuid";
import { invoke } from "@tauri-apps/api/core";

export function useAgent() {
  const [status, setStatus] = useState("not_detected");
  const [logs, setLogs] = useState([]);
  const [workspaceDir, setWorkspaceDir] = useState(
    `${window.HOME || ""}/InfraForge/workspaces`
  );

  useEffect(() => {
    // simple detection: if Tauri is present, agent is "ready"
    if (window.__TAURI__) {
      setStatus("ready");
    } else {
      setStatus("not_detected");
    }
  }, []);

  async function runGenerator(stack) {
    const jobId = uuidv4();

    const job = {
      id: jobId,
      source: "browser",
      workspace: "default",
      stack,
      status: "pending",
      started_at: "",
      ended_at: null,
      output_dir: "",
      last_log: null
    };

    // Append job to registry (Tauri backend)
    await invoke("append_job", { job });

    // Trigger runtime via protocol
    window.location.href =
      `infraforge://generation?job_id=${jobId}`;
  }

  return {
    logs,
    workspaceDir,
    runGenerator,
    status
  };
}
