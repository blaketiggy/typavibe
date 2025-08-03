// @ts-check
import { defineConfig } from 'astro/config';
import netlify from '@astrojs/netlify';

// https://astro.build/config
export default defineConfig({
  output: 'server',
  adapter: netlify(),
  devToolbar: {
    enabled: false
  },
  
  // Performance optimizations
  build: {
    inlineStylesheets: 'auto'
  },
  
  // Image optimization
  image: {
    service: {
      entrypoint: 'astro/assets/services/sharp'
    }
  },
  
  // Vite optimizations
  vite: {
    build: {
      rollupOptions: {
        output: {
          manualChunks: {
            'vendor': ['@supabase/supabase-js']
          }
        }
      }
    },
    optimizeDeps: {
      include: ['@supabase/supabase-js']
    }
  }
});
