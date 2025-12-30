import { useEffect, useState } from "react";
import { initAgent, checkAgent } from "./services/agent";
import AgentRequired from "./pages/AgentRequired";
import Generator from "./pages/Generator";

export default function App() {
  const [ready, setReady] = useState(false);
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    async function start() {
      // Try to initialize agent (may fail on public site)
      await initAgent();

      // Always try a health check
      const alive = await checkAgent();
      setReady(alive);

      // Mark that detection is complete
      setChecked(true);
    }
    start();
  }, []);

  // While checking, render nothing (or spinner later)
  if (!checked) return null;

  // Agent not available
  if (!ready) {
    return <AgentRequired onConnected={() => setReady(true)} />;
  }

  // Agent available
  return <Generator />;
}
