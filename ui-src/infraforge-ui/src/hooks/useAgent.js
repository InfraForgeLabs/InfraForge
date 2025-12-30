import { useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";

export function useAgent() {
  const [status, setStatus] = useState("checking");
  const [token, setToken] = useState(
    localStorage.getItem("infraforgeToken") || ""
  );
  const [logs, setLogs] = useState([]);
  const [jobId, setJobId] = useState(null);
  const [workspace, setWorkspace] = useState(
    localStorage.getItem("infraforgeWorkspace") || "default"
  );
  const [workspaceDir, setWorkspaceDir] = useState(null);

  /* -----------------------------
     Agent health
  ------------------------------*/
  useEffect(() => {
    invoke("agent_health")
      .then(() => setStatus(token ? "ready" : "pair"))
      .catch(() => setStatus("agent-down"));
  }, [token]);

  /* -----------------------------
     Workspace binding
  ------------------------------*/
  useEffect(() => {
    invoke("resolve_workspace_dir", { workspace })
      .then(setWorkspaceDir)
      .catch(console.error);
  }, [workspace]);

  /* -----------------------------
     Log streaming + severity parse
  ------------------------------*/
  useEffect(() => {
    let unlisten;

    listen("agent-log", (event) => {
      const line = event.payload;

      let level = "info";
      if (line.includes("ERROR")) level = "error";
      else if (line.includes("WARN")) level = "warn";

      setLogs((prev) => [...prev, { level, text: line }]);
    }).then((fn) => (unlisten = fn));

    return () => {
      if (unlisten) unlisten();
    };
  }, []);

  /* -----------------------------
     Run generator
  ------------------------------*/
  const runGenerator = async (stack, inputs = {}) => {
    setLogs([]);
    setStatus("running");

    const id = await invoke("next_job_id");
    setJobId(id);

    await invoke("start_stream", { token });
  };

  return {
    status,
    logs,
    jobId,
    workspace,
    setWorkspace,
    workspaceDir,
    runGenerator,
    hasToken: Boolean(token),
  };
}
