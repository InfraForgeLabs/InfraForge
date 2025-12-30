import { useEffect, useState } from "react";

export function useJobs() {
  const [jobs, setJobs] = useState([]);

  useEffect(() => {
    // 🌍 Public website → no desktop features
    if (typeof __PUBLIC_BUILD__ !== "undefined" && __PUBLIC_BUILD__) {
      setJobs([]);
      return;
    }

    // 🚫 Browser preview without Tauri
    if (typeof window === "undefined" || !("__TAURI__" in window)) {
      setJobs([]);
      return;
    }

    let cancelled = false;

    async function loadJobs() {
      try {
        const { readTextFile } = await import("@tauri-apps/api/fs");
        const { homeDir } = await import("@tauri-apps/api/path");

        const home = await homeDir();
        const path = `${home}/.infraforge/jobs.json`;

        const raw = await readTextFile(path);
        const parsed = JSON.parse(raw);

        if (!cancelled && parsed?.jobs) {
          setJobs(parsed.jobs);
        }
      } catch {
        if (!cancelled) setJobs([]);
      }
    }

    loadJobs();
    const interval = setInterval(loadJobs, 2000);

    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, []);

  return Array.isArray(jobs) ? jobs : [];
}
