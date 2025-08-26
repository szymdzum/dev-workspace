// @ts-check

import react from '@astrojs/react'
import { defineConfig } from 'astro/config'

// https://astro.build/config
export default defineConfig({
  integrations: [react()],
  vite: {
    resolve: {
      alias: {
        '@library/ui': new URL('../../libs/ui/src', import.meta.url).pathname,
      },
    },
  },
})
