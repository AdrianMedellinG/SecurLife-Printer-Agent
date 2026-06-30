module.exports = {
  apps: [
    {
      name: "securlife-printer-agent",
      script: "src/server.js",
      cwd: __dirname,
      exec_mode: "fork",
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: "256M",
      time: true,
      out_file: "tmp/pm2-out.log",
      error_file: "tmp/pm2-error.log",
      merge_logs: true,
      env: {
        NODE_ENV: "production"
      },
      env_production: {
        NODE_ENV: "production"
      }
    }
  ]
};
