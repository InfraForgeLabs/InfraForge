import { useAgent } from "./hooks/useAgent";
import { generatorSchemas } from "./schemas";

import Generator from "./pages/Generator";

export default function App() {
  const { status, logs, runGenerator } = useAgent();

  /*
    LOCKED RULE:
    - Schemas are LOCAL
    - Runtime NEVER provides schemas
    - No agent fallback logic
  */
  const schemaMap = Object.fromEntries(
    generatorSchemas.map((s) => [s.id, s])
  );

  return (
    <Generator
      status={status}
      logs={logs}
      runGenerator={runGenerator}
      schemaMap={schemaMap}
    />
  );
}
