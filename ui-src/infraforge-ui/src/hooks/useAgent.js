import { useEffect, useState } from "react";
import { v4 as uuidv4 } from "uuid";

// IMPORTANT:
// Do NOT import invoke at top-level.
// It breaks browser preview builds.
let invokeFn = null;

if (window.__TAURI__) {
  // Lazy-load only inside Tauri
  import("@tauri-apps/api/core").then(mod => {
    invokeFn = mod.invoke;
  });
}

/*
  InfraForge Agent Hook (LOCKED)
  - Browser-safe
  - Desktop-aware
  - No localhost
  - No schemas
  - No execution in browser
*/

export function useAgent() {
  const [status, setStatus] = useState("not_detected");
  const [logs] = useState([]);          // logs are agent-owned
  const [workspaceDir] = useState("");  // filled by agent later

  // Detect agent purely via Tauri presence
  useEffect(() => {
    if (window.__TAURI__) {
      setStatus("ready");
    } else {
      setStatus("not_detected");
    }
  }, []);

  async function runGenerator(stack) {
    const jobId = uuidv4();

    // 🚫 Browser preview: NO execution, NO protocol
    if (!window.__TAURI__ || !invokeFn) {
      console.info(
        "[InfraForge] Agent not available — browser preview mode"
      );
      return;
    }

    try {
      await invokeFn("append_job_ui", {
        job: {
          id: jobId,
          source: "browser",
          workspace: "default",
          stack,
          status: "pending",
          started_at: "",
          ended_at: null,
          output_dir: "",
          last_log: null
        }
      });

      // ✅ Desktop-only protocol trigger
      window.location.href =
        `infraforge://generation?job_id=${jobId}`;

    } catch (err) {
      console.error("[InfraForge] Failed to start generation:", err);
    }
  }

  return {
    status,
    logs: Array.isArray(logs) ? logs : [],
    workspaceDir,
    runGenerator
  };
}
