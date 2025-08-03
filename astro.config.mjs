// @ts-check
import { defineConfig } from 'astro/config';
import netlify from '@astrojs/netlify';

// https://astro.build/config
export default defineConfig({
  output: 'server', // Server-rendered pages
  adapter: netlify(),
  devToolbar: {
    enabled: false
  }
});
