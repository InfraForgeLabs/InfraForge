export async function onRequest() {
  return new Response(
    JSON.stringify({
      stacks: [
        "terraform",
        "docker",
        "helm",
        "kubernetes",
        "ansible",
        "argocd",
        "jenkins",
        "monitoring",
        "security"
      ],
      providers: ["aws", "azure", "gcp"]
    }),
    {
      headers: {
        "Content-Type": "application/json"
      }
    }
  );
}
