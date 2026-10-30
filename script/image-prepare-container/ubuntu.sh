#!/bin/bash -e

if [[ -z "${anodosysAppPath}" ]]; then
  >&2 echo "No anodosys app path defined!"
  exit 1
fi

if [[ -z "${anodosysUserVarPath}" ]]; then
  >&2 echo "No anodosys user var path defined!"
  exit 1
fi

if [[ -z "${systemName}" ]]; then
  >&2 echo "No system name specified!"
  exit 1
fi

scriptName="${0##*/}"

trim()
{
  echo -n "$1" | xargs
}

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help        Show this message
  --serverName  Server name

Example: ${scriptName} --serverName ws
EOF
}

serverName=
source "${anodosysAppPath}/prepare-parameters.sh"

if [[ -z "${serverName}" ]]; then
  >&2 echo "No server name specified!"
  usage
  exit 1
fi

logName "${systemName}" "${serverName}"

containerName="${systemName}_${serverName}"

containerCommand "${containerName}" "apt clean"
containerCommand "${containerName}" "apt autoclean"
containerCommand "${containerName}" "apt autoremove -y"
containerCommand "${containerName}" "rm -rf /var/lib/fix-mount-owners.first-start.done"
