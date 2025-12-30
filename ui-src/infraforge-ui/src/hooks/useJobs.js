import { useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/core";

export function useJobs() {
  const [jobs, setJobs] = useState([]);

  useEffect(() => {
    const refresh = () =>
      invoke("list_jobs_ui").then(setJobs).catch(console.error);

    refresh();
    const i = setInterval(refresh, 2000);
    return () => clearInterval(i);
  }, []);

  return jobs;
}
