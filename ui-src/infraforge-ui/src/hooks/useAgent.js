import { useEffect, useRef, useState } from "react";

const AGENT_URL = "http://127.0.0.1:7331";

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
    fetch(`${AGENT_URL}/health`)
      .then(() => setStatus(token ? "ready" : "pair"))
      .catch(() => setStatus("agent-down"));
  }, [token]);

  /* -----------------------------
     Schema Discovery (Agent)
  ------------------------------*/
  useEffect(() => {
    fetch(`${AGENT_URL}/schemas`)
      .then((r) => r.json())
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
  ------------------------------*/
  const runGenerator = (stack, inputs = {}) => {
    setLogs([]);
    setStatus("running");

    fetch(`${AGENT_URL}/generate/stream`, {
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
  };

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
    schemas,        // ← agent-discovered schemas (or null)
    hasToken: Boolean(token),
  };
}
