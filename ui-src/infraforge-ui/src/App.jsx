import { useState } from "react";
import { useAgent } from "./hooks/useAgent";
import { generatorSchemas as localSchemas } from "./schemas";
import SchemaForm from "./components/SchemaForm";

export default function App() {
  const { status, logs, pair, runGenerator, schemas } = useAgent();

  // Prefer agent schemas, fallback to local
  const schemaMap = schemas
    ? Object.fromEntries(schemas.map((s) => [s.id, s]))
    : localSchemas;

  const schemaIds = Object.keys(schemaMap);
  const [activeStack, setActiveStack] = useState(schemaIds[0]);

  const activeSchema = schemaMap[activeStack];

  return (
    <div style={styles.shell}>
      {/* ===== Header ===== */}
      <header style={styles.header}>
        <div style={styles.headerLeft}>
          <img
            src="/assets/infraforge-logo-saas-orange.svg"
            alt="InfraForge"
            style={styles.logo}
          />
          <span>InfraForge</span>
          <span style={styles.separator}>/</span>
          <span style={styles.subtitle}>Generator</span>
        </div>

        <span style={styles.badge}>
          {status === "ready"
            ? "Agent Connected"
            : status === "pair"
            ? "Pair Required"
            : status === "agent-down"
            ? "Agent Not Detected"
            : status === "running"
            ? "Running"
            : "Checking"}
        </span>
      </header>

      {/* ===== Main ===== */}
      <main style={styles.main}>
        {/* Agent Down */}
        {status === "agent-down" && (
          <StateBlock
            title="Local InfraForge Agent not detected"
            hint="infraforge agent start"
          />
        )}

        {/* Pairing */}
        {status === "pair" && <PairBlock onPair={pair} />}

        {/* Ready / Running */}
        {(status === "ready" || status === "running") && (
          <div style={styles.layout}>
            {/* Sidebar */}
            <aside style={styles.sidebar}>
              {schemaIds.map((id) => (
                <button
                  key={id}
                  onClick={() => setActiveStack(id)}
                  style={{
                    ...styles.stackButton,
                    ...(id === activeStack
                      ? styles.stackButtonActive
                      : {}),
                  }}
                >
                  {schemaMap[id].name}
                </button>
              ))}
            </aside>

            {/* Content */}
            <section style={styles.content}>
              <SchemaForm
                schema={activeSchema}
                onSubmit={(inputs) =>
                  runGenerator(activeSchema.id, inputs)
                }
                disabled={status === "running"}
              />

              <pre style={styles.console}>
                {logs.length
                  ? logs.join("\n")
                  : "Waiting for generator output..."}
              </pre>
            </section>
          </div>
        )}
      </main>
    </div>
  );
}

/* ==============================
   Small UI Blocks
============================== */

function StateBlock({ title, hint }) {
  return (
    <div style={styles.center}>
      <h2>{title}</h2>
      <pre style={styles.code}>{hint}</pre>
    </div>
  );
}

function PairBlock({ onPair }) {
  return (
    <div style={styles.center}>
      <h2>Pair InfraForge Agent</h2>
      <pre style={styles.code}>infraforge agent token</pre>
      <input
        style={styles.input}
        placeholder="Paste agent token"
        onChange={(e) => onPair(e.target.value)}
      />
    </div>
  );
}

/* ==============================
   Styles (desktop-safe)
============================== */

const styles = {
  shell: {
    minHeight: "100vh",
    display: "flex",
    flexDirection: "column",
  },

  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "10px 18px",
    borderBottom: "1px solid var(--border)",
    background: "rgba(13,17,23,0.9)",
  },

  headerLeft: {
    display: "flex",
    alignItems: "center",
    gap: "10px",
    fontWeight: 600,
  },

  logo: { height: "22px" },
  separator: { color: "var(--muted)" },
  subtitle: { color: "var(--accent)" },

  badge: {
    fontSize: "12px",
    padding: "4px 8px",
    border: "1px solid var(--border)",
    borderRadius: "6px",
    color: "var(--muted)",
  },

  main: {
    flex: 1,
    padding: "20px",
  },

  layout: {
    display: "grid",
    gridTemplateColumns: "220px 1fr",
    gap: "20px",
  },

  sidebar: {
    display: "flex",
    flexDirection: "column",
    gap: "8px",
  },

  stackButton: {
    padding: "10px",
    borderRadius: "8px",
    border: "1px solid var(--border)",
    background: "transparent",
    color: "var(--fg)",
    cursor: "pointer",
    textAlign: "left",
  },

  stackButtonActive: {
    borderColor: "var(--accent)",
    color: "var(--accent)",
  },

  content: {
    display: "flex",
    flexDirection: "column",
    gap: "16px",
  },

  console: {
    background: "#0b0f14",
    border: "1px solid var(--border)",
    borderRadius: "8px",
    padding: "12px",
    height: "280px",
    overflow: "auto",
    color: "#7ee787",
    fontFamily: "monospace",
  },

  center: {
    maxWidth: "420px",
    margin: "60px auto",
    textAlign: "center",
  },

  code: {
    background: "#161b22",
    border: "1px solid var(--border)",
    borderRadius: "8px",
    padding: "10px",
    marginTop: "10px",
  },

  input: {
    width: "100%",
    marginTop: "12px",
    padding: "10px",
    borderRadius: "8px",
    border: "1px solid var(--border)",
    background: "#0d1117",
    color: "var(--fg)",
  },
};
