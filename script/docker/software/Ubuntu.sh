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
apt-get install -y wget 2>&1
apt-get install -y bash 2>&1

wget -q -O - https://raw.githubusercontent.com/cosyses/app/master/setup.sh | bash

cosyses \
  --applicationName OpenSSH \
  --applicationVersion "${openSshVersion}"

cosyses \
  --applicationName Tini \
  --applicationVersion 0.19

generate-ssh-key
echo "Generated public key:"
get-ssh-public-key

echo "Creating start script at: /usr/local/bin/ubuntu.sh"
# shellcheck disable=SC2154
cat <<EOF > /usr/local/bin/ubuntu.sh
#!/usr/bin/env bash
trap stop SIGTERM SIGINT SIGQUIT SIGHUP ERR
stop() {
  echo "Stopping container"
  exit
}
for command in "\$@"; do
  echo "Run: \${command}"
  /bin/bash "\${command}"
done
echo "Container up"
tail -f /dev/null & wait \$!
EOF
chmod +x /usr/local/bin/ubuntu.sh
