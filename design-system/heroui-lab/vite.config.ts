import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { fileURLToPath } from 'node:url';

const here = (p: string) => fileURLToPath(new URL(p, import.meta.url));

export default defineConfig({
  root: here('./playground'),
  plugins: [react(), tailwindcss()],
  server: { port: 5181, strictPort: true },
  build: { outDir: here('./dist-playground'), emptyOutDir: true },
});
