import { useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/core";

export function useAgent() {
  const [status, setStatus] = useState("checking");
  const [token, setToken] = useState(
    localStorage.getItem("infraforgeToken") || ""
  );
  const [logs, setLogs] = useState([]);

  /* -----------------------------
     Agent health (UI → Rust → Agent)
  ------------------------------*/
  useEffect(() => {
    invoke("agent_health")
      .then(() => setStatus(token ? "ready" : "pair"))
      .catch(() => setStatus("agent-down"));
  }, [token]);

  /* -----------------------------
     Pair agent
  ------------------------------*/
  const pair = (newToken) => {
    localStorage.setItem("infraforgeToken", newToken);
    setToken(newToken);
  };

  /* -----------------------------
     Run generator
  ------------------------------*/
  const runGenerator = async (stack, inputs = {}) => {
    setLogs([]);
    setStatus("running");

    await invoke("start_stream", { token });
  };

  return {
    status,
    logs,
    pair,
    runGenerator,
    hasToken: Boolean(token),
  };
}
