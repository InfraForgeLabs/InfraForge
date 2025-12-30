let agentUrl = "";
let agentToken = "";

const IS_PUBLIC =
  typeof __PUBLIC_BUILD__ !== "undefined" && __PUBLIC_BUILD__;

export async function initAgent() {
  if (IS_PUBLIC) return false;
  return false;
}

export async function checkAgent() {
  if (IS_PUBLIC) return false;
  return false;
}
