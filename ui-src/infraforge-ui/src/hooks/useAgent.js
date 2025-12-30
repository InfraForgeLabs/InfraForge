import { useEffect, useState } from "react";
import { fetch } from "@tauri-apps/plugin-http";
import { listen } from "@tauri-apps/api/event";
import { invoke } from "@tauri-apps/api/core";

const AGENT_URL = "http://localhost:7331";

export function useAgent() {
  const [status, setStatus] = useState("checking"); // checking | agent-down | pair | ready | running
  const [token, setToken] = useState(
    localStorage.getItem("infraforgeToken") || ""
  );
  const [logs, setLogs] = useState([]);

  /* -----------------------------
     Agent health check
  ------------------------------*/
  useEffect(() => {
    fetch(`${AGENT_URL}/health`)
      .then(() => setStatus(token ? "ready" : "pair"))
      .catch(() => setStatus("agent-down"));
  }, [token]);

  /* -----------------------------
     Listen for logs from Rust
  ------------------------------*/
useEffect(() => {
  let cancelled = false;

  async function checkHealth() {
    try {
      const res = await fetch(`${AGENT_URL}/health`);

      // IMPORTANT: plugin-http requires explicit check
      if (!res.ok) {
        throw new Error(`Agent health failed: ${res.status}`);
      }

      if (!cancelled) {
        setStatus(token ? "ready" : "pair");
      }
    } catch (err) {
      console.error("Agent health check failed:", err);
      if (!cancelled) {
        setStatus("agent-down");
      }
    }
  }

  checkHealth();

  return () => {
    cancelled = true;
  };
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

    await fetch(`${AGENT_URL}/generate`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Agent-Token": token,
      },
      body: JSON.stringify({ stack, inputs }),
    });

    // start SSE proxy via Rust
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

