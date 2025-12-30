const IS_PUBLIC =
  typeof window !== "undefined" &&
  window.location.protocol === "https:";

let agentUrl = "";
let agentToken = "";

// 🚫 Public web build: agent is disabled
if (IS_PUBLIC) {
  export async function initAgent() {
    return false;
  }

  export async function checkAgent() {
    return false;
  }
} else {
  // 🖥️ Local / Desktop mode only

  async function bootstrapLocalAgent() {
    try {
      agentUrl = "http://127.0.0.1:7331";
      const res = await fetch(`${agentUrl}/health`);
      return res.ok;
    } catch {
      return false;
    }
  }

  export async function initAgent() {
    return await bootstrapLocalAgent();
  }

  export async function checkAgent() {
    try {
      const res = await fetch(`${agentUrl}/health`);
      return res.ok;
    } catch {
      return false;
    }
  }
}
