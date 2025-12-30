import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  base: "/generation/",
  build: {
    outDir: "../../docs/generation",
    emptyOutDir: true,
    rollupOptions: {
      external: [
        "@tauri-apps/api/fs",
        "@tauri-apps/api/path",
      ],
    },
  },
});
