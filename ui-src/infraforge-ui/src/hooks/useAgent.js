import { useEffect, useRef, useState } from "react";
import { fetch as tauriFetch } from "@tauri-apps/plugin-http";

const AGENT_URL = "http://127.0.0.1:7331";

/* -----------------------------
   Unified HTTP Fetch
   - Browser  → window.fetch
   - Desktop  → Tauri HTTP plugin
------------------------------*/
async function httpFetch(url, options = {}) {
  try {
    if (window.__TAURI__) {
      return tauriFetch(url, {
        method: options.method || "GET",
        headers: options.headers,
        body: options.body,
      });
    }
    return fetch(url, options);
  } catch (err) {
    throw err;
  }
}

export function useAgent() {
  const [status, setStatus] = useState("checking"); // checking | agent-down | pair | ready | running
  const [token, setToken] = useState(
    localStorage.getItem("infraforgeToken") || ""
  );
  const [logs, setLogs] = useState([]);
  const [schemas, setSchemas] = useState(null);

  const eventSourceRef = useRef(null);

  /* -----------------------------
     Agent Health
  ------------------------------*/
  useEffect(() => {
    httpFetch(`${AGENT_URL}/health`)
      .then(() => setStatus(token ? "ready" : "pair"))
      .catch(() => setStatus("agent-down"));
  }, [token]);

  /* -----------------------------
     Schema Discovery (Agent)
  ------------------------------*/
  useEffect(() => {
    httpFetch(`${AGENT_URL}/schemas`)
      .then((r) => (r.json ? r.json() : r))
      .then((data) => {
        if (data?.schemas) {
          setSchemas(data.schemas);
        }
      })
      .catch(() => {
        // silent fallback to local schemas
        setSchemas(null);
      });
  }, []);

  /* -----------------------------
     Pair Agent
  ------------------------------*/
  const pair = (newToken) => {
    localStorage.setItem("infraforgeToken", newToken);
    setToken(newToken);
  };

  /* -----------------------------
     Run Generator (SSE)
     NOTE: EventSource works in browser.
     Desktop SSE upgrade comes later.
  ------------------------------*/
  const runGenerator = (stack, inputs = {}) => {
    setLogs([]);
    setStatus("running");

    httpFetch(`${AGENT_URL}/generate/stream`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Agent-Token": token,
      },
      body: JSON.stringify({ stack, inputs }),
    }).catch(() => {
      setLogs(["Failed to start generator"]);
      setStatus("ready");
    });

    if (rememberEventSource()) return;
  };

  function rememberEventSource() {
    if (window.__TAURI__) {
      // Desktop: SSE will be handled later via Rust stream
      setLogs((l) => [...l, "Waiting for generator output..."]);
      return true;
    }

    if (eventSourceRef.current) {
      eventSourceRef.current.close();
    }

    const es = new EventSource(`${AGENT_URL}/generate/stream`);
    eventSourceRef.current = es;

    es.onmessage = (e) => {
      if (e.data === "[DONE]") {
        es.close();
        setStatus("ready");
        return;
      }
      setLogs((prev) => [...prev, e.data]);
    };

    es.onerror = () => {
      setLogs((prev) => [...prev, "Stream error"]);
      es.close();
      setStatus("ready");
    };

    return false;
  }

  /* -----------------------------
     Cleanup (desktop-safe)
  ------------------------------*/
  useEffect(() => {
    return () => {
      if (eventSourceRef.current) {
        eventSourceRef.current.close();
      }
    };
  }, []);

  return {
    status,
    logs,
    pair,
    runGenerator,
    schemas,        // agent-discovered schemas (or null)
    hasToken: Boolean(token),
  };
}
