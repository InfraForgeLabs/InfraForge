if (typeof window !== "undefined") {
  const origFetch = window.fetch;

  window.fetch = (...args) => {
    const url = String(args[0] || "");
    if (url.includes("127.0.0.1") || url.includes("localhost")) {
      throw new Error(
        "[InfraForge] Browser attempted forbidden localhost access"
      );
    }
    return origFetch(...args);
  };
}
