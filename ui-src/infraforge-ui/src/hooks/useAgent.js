import { useEffect, useState } from "react";
import { v4 as uuidv4 } from "uuid";

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
  const [invokeFn, setInvokeFn] = useState(null);

  // Detect agent + lazy-load Tauri safely
  useEffect(() => {
    if (typeof window === "undefined") {
      setStatus("not_detected");
      return;
    }

    if ("__TAURI__" in window) {
      setStatus("ready");

      // Lazy-load invoke ONLY in desktop runtime
      import("@tauri-apps/api/core")
        .then(mod => setInvokeFn(() => mod.invoke))
        .catch(() => {
          console.warn("[InfraForge] Failed to load Tauri core");
          setInvokeFn(null);
        });
    } else {
      setStatus("not_detected");
    }
  }, []);

  async function runGenerator(stack) {
    const jobId = uuidv4();

    // 🚫 Browser preview: NO execution, NO protocol
    if (status !== "ready" || !invokeFn) {
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
