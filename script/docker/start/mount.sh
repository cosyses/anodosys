#!/usr/bin/env bash
# Fix the ownership of the directories Docker created for the mount points, and
# do so only the first time a container is started.
#
# Docker creates the missing parent directories of bind mounts as root. Each of
# those directories is chown'ed (non-recursively) to the uid:gid of the first
# mount found below it, which is the owner of that mount on the host (valid
# when the container does not use user-namespace remapping, see
# /proc/self/uid_map). Directories that already have the right owner are
# skipped, and the mounts themselves are never touched. Nothing is printed.
# Needs root.
#
# Mounts considered: everything except the root overlay, virtual filesystems and
# the files Docker mounts itself (/etc/hostname, /etc/hosts, /etc/resolv.conf),
# which are recognised by their source living under .../docker/containers/.
#
# A parent directory counts as created by Docker when its mtime equals its
# birth time (within 1s): it was never modified since creation. Directories
# from the image keep their old mtime, so they are not touched. This is a
# heuristic; `docker diff <container>` on the host is authoritative.
#
# First start only: a marker file in the container's writable layer records the
# first run. That layer survives `docker stop` / `docker start` / `docker
# restart`, so later starts skip the work, but it is discarded when the
# container is removed and recreated, so a new container runs it again (which it
# needs, since the directories Docker creates for the mounts are new then too).
# The marker is only written if the run succeeded, so a failed first run is
# retried on the next start. Its location can be set with FIRST_START_MARKER;
# do not point it at /run, /tmp or a mounted path.
#
# Use it as (or from) the container entrypoint, before starting the main
# process, e.g. in a shell entrypoint:
#   /usr/local/bin/fix-mount-owners.sh
#   exec "$@"
#
# Options:
#   --force, -f    run even if the marker exists (the marker is still written)
#   --dry-run, -n  change nothing and write no marker; print the chown commands
#                  that would be run (ignores the marker)
# Usage: ./fix-mount-owners.sh [--force | --dry-run]

set -euo pipefail

MARKER="${FIRST_START_MARKER:-/var/lib/fix-mount-owners.first-start.done}"
VIRTUAL='^(proc|sysfs|cgroup2?|devpts|mqueue|tmpfs|devtmpfs)$'
DOCKER_MANAGED='/docker/containers/'

FORCE=0
DRY_RUN=0
case "${1:-}" in
    '') ;;
    --force|-f) FORCE=1 ;;
    --dry-run|-n) DRY_RUN=1 ;;
    *) echo "Usage: $0 [--force | --dry-run]" >&2; exit 2 ;;
esac

if [ "$DRY_RUN" -eq 0 ] && [ "$FORCE" -eq 0 ] && [ -e "$MARKER" ]; then
    exit 0
fi

list_paths() {
    if command -v findmnt >/dev/null 2>&1; then
        findmnt -R -l -n -o TARGET,FSTYPE,SOURCE \
            | awk -v re="$VIRTUAL" -v dm="$DOCKER_MANAGED" '
                $2 !~ re && $1 != "/" && index($3, dm) == 0 {print $1}'
    else
        # Fallback: /proc/self/mountinfo
        # $4 = path on the source filesystem, $5 = mount point,
        # fs type is the first field after the "-" separator.
        awk -v re="$VIRTUAL" -v dm="$DOCKER_MANAGED" '
            {
                for (i = 1; i <= NF; i++) if ($i == "-") break
                if ($(i+1) !~ re && $5 != "/" && index($4, dm) == 0) print $5
            }' /proc/self/mountinfo
    fi
}

# True if the directory was created after container start and never modified.
created_by_docker() {
    local birth mtime
    read -r birth mtime < <(stat -c '%W %Y' "$1")
    [ "$birth" -gt 0 ] && [ $((mtime - birth)) -le 1 ] && [ $((birth - mtime)) -le 1 ]
}

declare -A seen

while IFS= read -r mount; do
    owner=$(stat -c '%u:%g' "$mount")

    dir=$(dirname "$mount")
    while [ "$dir" != / ]; do
        # Only the first mount found below a directory is considered.
        if [ -z "${seen[$dir]+x}" ]; then
            seen[$dir]=1
            if created_by_docker "$dir" && [ "$(stat -c '%u:%g' "$dir")" != "$owner" ]; then
                if [ "$DRY_RUN" -eq 1 ]; then
                    printf 'chown %q %q\n' "$owner" "$dir"
                else
                    chown "$owner" "$dir"
                fi
            fi
        fi
        dir=$(dirname "$dir")
    done
done < <(list_paths)

if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$MARKER")"
    date -u +%Y-%m-%dT%H:%M:%SZ > "$MARKER"
fi
