/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export', // Enable static export for Render Static Site
  // Enable experimental features if needed
  experimental: {
    // Enable if using app directory features
  },

  // Image optimization settings
  images: {
    domains: ['localhost'], // Add your production domain here
    unoptimized: true, // Required for static export
  },


  // Reduce dev-time memory usage by avoiding watching heavy root-level folders
  // and backend-related artifacts that are irrelevant to the Next.js app.
  webpackDevMiddleware: (config) => {
    if (config.watchOptions && !config.watchOptions.ignored) {
      config.watchOptions.ignored = []
    }

    const ignored = config.watchOptions?.ignored || []

    const heavyGlobs = [
      '../backend/**',
      '../worker/**',
      '../logs/**',
      '../.venv/**',
      '../venv/**',
      '../dev.db',
      '../test.db',
      '../output.mp3',
      '../server.log',
    ]

    config.watchOptions.ignored = Array.isArray(ignored)
      ? [...ignored, ...heavyGlobs]
      : [ignored, ...heavyGlobs]

    return config
  },
}

module.exports = nextConfig
