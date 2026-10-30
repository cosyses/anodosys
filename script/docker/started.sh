#!/usr/bin/env bash
if [[ ! -f /var/run/container.pid ]]; then
  exit 1
fi
containerId=$(cat /var/run/container.pid)
if [[ $(pgrep --ns "${containerId}" >/dev/null && echo "1" || echo "0") == 1 ]]; then
  exit 0
else
  exit 1
fi
