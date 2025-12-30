import { fetch } from "@tauri-apps/plugin-http";

const AGENT_URL = "http://127.0.0.1:7331";

export async function checkAgent() {
  try {
    const res = await fetch(`${AGENT_URL}/health`, {
      method: "GET",
    });
    return res.ok;
  } catch {
    return false;
  }
}

