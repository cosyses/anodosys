#!/usr/bin/env bash
if [[ ! -f /var/run/container.pid ]]; then
  exit 1
fi
containerId=$(cat /var/run/container.pid)
# Ready while the entrypoint process is alive. kill -0 instead of pgrep --ns, which finds nothing with procps-ng 4.0.4
# (RHEL 10).
if kill -0 "${containerId}" 2>/dev/null; then
  exit 0
else
  exit 1
fi
