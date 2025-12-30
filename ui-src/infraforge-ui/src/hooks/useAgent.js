import { useState, useEffect } from "react";
import { v4 as uuidv4 } from "uuid";
import { invoke } from "@tauri-apps/api/core";

/*
  Agent detection rules (LOCKED):
  - Browser NEVER talks to localhost
  - If Tauri is present → agent is assumed available
  - Actual execution happens via protocol dispatch
*/

export function useAgent() {
  const [status, setStatus] = useState("not_detected");
  const [logs, setLogs] = useState([]);
  const [workspaceDir] = useState(
    `${window.HOME || ""}/InfraForge/workspaces`
  );

  // 🔐 Agent detection: Tauri presence ONLY
  useEffect(() => {
    if (window.__TAURI__) {
      setStatus("ready");
    } else {
      setStatus("not_detected");
    }
  }, []);

  async function runGenerator(stack) {
    if (!window.__TAURI__) {
      console.warn("InfraForge runtime not available");
      return;
    }

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

    // 1️⃣ Write job entry (single source of truth)
    await invoke("append_job", { job });

    // 2️⃣ Trigger runtime via protocol
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
