#!/usr/bin/env bash
trap stop SIGTERM SIGINT SIGQUIT SIGHUP ERR
stop() {
  echo "Stopping container"
  stopScripts=( $(find /usr/local/lib/stop -type f -name "*.sh" | sort -n) )
  for stopScript in "${stopScripts[@]}"; do
    echo "--- Executing script: ${stopScript} ---"
    chmod +x "${stopScript}"
    bash -c "${stopScript}"
  done
  exit
}
echo "Starting container"
rm -rf /var/run/container.pid
startScripts=( $(find /usr/local/lib/start -type f -name "*.sh" | sort -n) )
for startScript in "${startScripts[@]}"; do
  echo "--- Executing script: ${startScript} ---"
  chmod +x "${startScript}"
  bash -c "${startScript}"
done
for command in "$@"; do
  echo "--- Executing command: ${command} ---"
  /bin/bash "${command}"
done
echo "Container is up"
echo "$$" > /var/run/container.pid
if [[ -f /usr/local/lib/start/container.out ]]; then
  tail -f /usr/local/lib/start/container.out & wait $!
else
  tail -f /dev/null & wait $!
fi
