import { useAgent } from "./hooks/useAgent";
import Generator from "./pages/Generator";
import * as Schemas from "./schemas";

/*
  App is the ROOT boundary.
  Anything crashing here kills the entire app.
*/

export default function App() {
  const { status, logs, runGenerator } = useAgent();

  // 🔒 HARD NORMALIZATION (CRITICAL)
  const generatorSchemas = Array.isArray(Schemas.generatorSchemas)
    ? Schemas.generatorSchemas
    : Object.values(Schemas.generatorSchemas || {});

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
