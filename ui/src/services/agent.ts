let agentUrl = "";
let agentToken = "";

const IS_PUBLIC =
  location.hostname !== "localhost" &&
  location.hostname !== "127.0.0.1";

/**
 * Bootstrap agent using local defaults only.
 * No /agent/info endpoint exists on the agent.
 */
async function bootstrapLocalAgent() {
  if (IS_PUBLIC) return false;

  try {
    agentUrl = "http://127.0.0.1:7331";

    // token is stored locally by the agent itself
    const cachedToken = localStorage.getItem("infraforge_token");
    if (cachedToken) {
      agentToken = cachedToken;
    }

    // Validate agent availability
    const res = await fetch(`${agentUrl}/health`);
    if (!res.ok) return false;

    localStorage.setItem("infraforge_agent_url", agentUrl);
    return true;
  } catch {
    return false;
  }
}

export async function initAgent() {
  if (IS_PUBLIC) return false;

  // 1️⃣ Try cached info
  const cachedUrl = localStorage.getItem("infraforge_agent_url");
  const cachedToken = localStorage.getItem("infraforge_token");

  if (cachedUrl) agentUrl = cachedUrl;
  if (cachedToken) agentToken = cachedToken;

  if (agentUrl) {
    try {
      const res = await fetch(`${agentUrl}/health`);
      if (res.ok) return true;
    } catch {
      /* fall through */
    }
  }

  // 2️⃣ Try local bootstrap
  return await bootstrapLocalAgent();
}

export async function checkAgent() {
  if (!agentUrl) return false;

  try {
    const res = await fetch(`${agentUrl}/health`);
    return res.ok;
  } catch {
    return false;
  }
}
