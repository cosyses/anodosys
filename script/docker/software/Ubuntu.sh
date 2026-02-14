#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help            Show this message
  --containerName   Container to execute the script in
  --openSshVersion  OpenSSH version

Example: ${scriptName} --containerName server --openSshVersion 9.0
EOF
}

openSshVersion=
source "/prepare-parameters.sh"

if [[ -z "${openSshVersion}" ]]; then
  >&2 echo "No OpenSSH version specified!"
  echo ""
  usage
  exit 1
fi

apt-get update
DEBIAN_FRONTEND="noninteractive" apt-get install -y wget 2>&1
DEBIAN_FRONTEND="noninteractive" apt-get install -y bash 2>&1

wget -q -O - https://raw.githubusercontent.com/cosyses/app/master/setup.sh | bash

install-package curl
install-package nano
install-package less

cosyses \
  --applicationName OpenSSH \
  --applicationVersion "${openSshVersion}"

cosyses \
  --applicationName Tini \
  --applicationVersion 0.19

generate-ssh-key
echo "Generated public key:"
get-ssh-public-key

mkdir -p /usr/local/lib/start

cat <<EOF > /usr/local/lib/start/00-cosyes.sh
#!/usr/bin/env bash
if [[ -f /usr/local/etc/.anodosys ]]; then
  source /usr/local/etc/.anodosys
fi
if [[ ! -v NO_COSYSES_UPDATE ]]; then
  cosyses update
fi
EOF
chmod +x /usr/local/lib/start/00-cosyes.sh

cat <<EOF > /usr/local/lib/start/80-ssh.sh
#!/usr/bin/env bash
if [[ -f /usr/local/etc/.anodosys ]]; then
  source /usr/local/etc/.anodosys
fi
if [[ ! -v NO_SSH_SERVER ]]; then
  /usr/local/bin/openssh.sh
fi
EOF
chmod +x /usr/local/lib/start/80-ssh.sh

mkdir -p /usr/local/lib/stop

cat <<EOF > /usr/local/lib/stop/80-ssh.sh
#!/usr/bin/env bash
if [[ -f /usr/local/etc/.anodosys ]]; then
  source /usr/local/etc/.anodosys
fi
if [[ ! -v NO_SSH_SERVER ]]; then
  /etc/init.d/ssh stop
fi
EOF
chmod +x /usr/local/lib/stop/80-ssh.sh

echo "Creating start script at: /usr/local/bin/cosyses.sh"
# shellcheck disable=SC2154
cat <<EOF > /usr/local/bin/cosyses.sh
#!/usr/bin/env bash
trap stop SIGTERM SIGINT SIGQUIT SIGHUP ERR
stop() {
  echo "Stopping container"
  stopScripts=( \$(find /usr/local/lib/stop -type f -name "*.sh" | sort -n) )
  for stopScript in "\${stopScripts[@]}"; do
    echo "--- Executing script: \${stopScript} ---"
    chmod +x "\${stopScript}"
    bash -c "\${stopScript}"
  done
  exit
}
echo "Starting container"
rm -rf /var/run/container.pid
startScripts=( \$(find /usr/local/lib/start -type f -name "*.sh" | sort -n) )
for startScript in "\${startScripts[@]}"; do
  echo "--- Executing script: \${startScript} ---"
  chmod +x "\${startScript}"
  bash -c "\${startScript}"
done
for command in "\$@"; do
  echo "--- Executing command: \${command} ---"
  /bin/bash "\${command}"
done
echo "Container is up"
echo "\$\$" > /var/run/container.pid
if [[ -f /usr/local/lib/start/container.out ]]; then
  tail -f /usr/local/lib/start/container.out & wait \$!
else
  tail -f /dev/null & wait \$!
fi
EOF
chmod +x /usr/local/bin/cosyses.sh

echo "Creating started check script at: /usr/local/bin/started.sh"
# shellcheck disable=SC2154
cat <<EOF > /usr/local/bin/started.sh
#!/usr/bin/env bash
if [[ ! -f /var/run/container.pid ]]; then
  exit 1
fi
containerId=\$(cat /var/run/container.pid)
if [[ \$(pgrep --ns "\${containerId}" >/dev/null && echo "1" || echo "0") == 1 ]]; then
  exit 0
else
  exit 1
fi
EOF
chmod +x /usr/local/bin/started.sh
