import { useEffect, useState } from "react";

/*
  useJobs (LOCKED)
  - Browser preview: returns empty array
  - Desktop (Tauri): reads jobs.json via invoke
*/

export function useJobs() {
  const [jobs, setJobs] = useState([]);

  useEffect(() => {
    // 🚫 Browser preview — no agent
    if (!window.__TAURI__) {
      setJobs([]);
      return;
    }

    let cancelled = false;

    async function load() {
      try {
        const { invoke } = await import("@tauri-apps/api/core");
        const data = await invoke("list_jobs_ui");
        if (!cancelled && Array.isArray(data)) {
          setJobs(data);
        }
      } catch (err) {
        console.error("[InfraForge] Failed to load jobs:", err);
      }
    }

    load();
    const id = setInterval(load, 2000);

    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, []);

  return jobs;
}
