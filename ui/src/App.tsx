import { useEffect, useState } from "react";
import { initAgent, checkAgent } from "./services/agent";
import AgentRequired from "./pages/AgentRequired";
import Generator from "./pages/Generator";

export default function App() {
  const [ready, setReady] = useState(false);
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    async function start() {
      const ok = await initAgent();
      const alive = ok ? await checkAgent() : false;
      setReady(alive);
      setChecked(true);
    }
    start();
  }, []);

  if (!checked) return null;
  if (!ready) return <AgentRequired />;

  return <Generator />;
}
