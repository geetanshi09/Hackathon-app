// import react from "@vitejs/plugin-react"
// import { defineConfig } from "vite"



// export default defineConfig({
//   plugins: [react()],
//   resolve: {
//     alias: {
//      '@': '/src',
//     },
//   },
// })

import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': '/src',
    },
  },
  server: {
    proxy: {
      '/recommend': {
        target: 'http://127.0.0.1:5000',
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/recommend/, ''),
      },
    },
  },
});

