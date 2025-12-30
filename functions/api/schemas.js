export async function onRequest() {
  return new Response(
    JSON.stringify({
      stacks: ["terraform", "docker", "helm", "kubernetes"],
      providers: ["aws", "azure", "gcp"]
    }),
    {
      headers: {
        "Content-Type": "application/json"
      }
    }
  );
}
