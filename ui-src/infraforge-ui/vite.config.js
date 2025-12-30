import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  base: "/generation/",
  define: {
    __PUBLIC_BUILD__: true,
  },
  build: {
    outDir: "../../docs/generation",
    emptyOutDir: true,
  },
});
