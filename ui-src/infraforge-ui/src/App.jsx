import { useEffect, useState } from "react";

const AGENT_URL = "http://127.0.0.1:7331";

export default function App() {
  const [status, setStatus] = useState("checking");
  const [token, setToken] = useState(localStorage.getItem("infraforgeToken") || "");
  const [logs, setLogs] = useState([]);

  useEffect(() => {
    fetch(`${AGENT_URL}/health`)
      .then(() => setStatus(token ? "ready" : "pair"))
      .catch(() => setStatus("agent-down"));
  }, [token]);

  if (status === "agent-down") {
    return (
      <div className="p-8 text-center">
        <h1 className="text-2xl font-bold text-red-600">Agent not running</h1>
        <p>Run: <code>infraforge agent start</code></p>
      </div>
    );
  }

  if (status === "pair") {
    return (
      <div className="p-8 max-w-md mx-auto">
        <h1 className="text-2xl font-bold mb-4">Pair InfraForge Agent</h1>
        <p className="mb-2">Run:</p>
        <pre className="bg-gray-100 p-2 mb-4">infraforge agent token</pre>
        <input
          className="border p-2 w-full"
          placeholder="Paste token"
          value={token}
          onChange={(e) => {
            localStorage.setItem("infraforgeToken", e.target.value);
            setToken(e.target.value);
          }}
        />
      </div>
    );
  }

  const run = (stack) => {
    fetch(`${AGENT_URL}/generate/stream`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Agent-Token": token,
      },
      body: JSON.stringify({ stack }),
    });

    const es = new EventSource(`${AGENT_URL}/generate/stream`);
    es.onmessage = (e) => {
      setLogs((l) => [...l, e.data]);
      if (e.data === "[DONE]") es.close();
    };
  };

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6 text-orange-500">InfraForge</h1>

      <div className="grid grid-cols-2 gap-4 mb-6">
        {["jenkins","terraform","aws","ansible","docker","helm","k8s","monitoring","security","argocd"].map((s) => (
          <button
            key={s}
            className="border p-3 rounded hover:bg-gray-100"
            onClick={() => run(s)}
          >
            {s}
          </button>
        ))}
      </div>

      <pre className="bg-black text-green-400 p-4 h-64 overflow-auto">
        {logs.join("\n")}
      </pre>
    </div>
  );
}
