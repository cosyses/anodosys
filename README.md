# Cosyses extension for Anodosys

This [Anodosys](https://github.com/anodosys/app) extension builds the Cosyses base images and provides the init system they use. The images have [Cosyses](https://github.com/cosyses/app) preinstalled, plus OpenSSH and Tini installed with Cosyses, use Tini as entrypoint and run `cosyses update` on start.

## Images

| Image | Releases | Base image |
|---|---|---|
| `cosyses/ubuntu` | 16.04, 18.04, 20.04, 22.04, 24.04, 26.04 | `ubuntu` |
| `cosyses/alpine` | 3.23, 3.24 (also `-arm` for arm64) | `alpine`, `arm64v8/alpine` |
| `cosyses/debian` | 12, 13 (also `-arm`) | `debian` |
| `cosyses/rhel` | 9, 10 (also `-arm`) | `registry.access.redhat.com/ubi<release>/ubi` |
| `cosyses/fedora` | 44, 45 (also `-arm`) | `fedora` |
| `cosyses/opensuse` | 15.6, 16.0 (also `-arm`) | `opensuse/leap` |

The `-arm` images are built on amd64 under QEMU from the same base images (`<release>-arm` directories with `containerPlatform: linux/arm64`). Docker's containerd image store keeps the platforms of a tag apart, so the arm64 pull does not replace the local amd64 base image.

## Building an image

The Docker Hub password goes into `build/cosyses.local.json` (copy `build/cosyses.local.json.dist`; the file is not tracked). Then build and push an image from its release directory:

```sh
cd build/OS/Debian/13
ads build      # fails if the image exists already
ads rebuild    # builds and pushes it again
```

Each release directory only sets the release and the OpenSSH version. The distribution file next to it (`ubuntu.json`, `alpine.json`, `debian.json`, `rhel.json`, `fedora.json`, `opensuse.json`) sets the base and target image; Debian, RHEL, Fedora and openSUSE share `build/OS/linux.json`. To add a release, copy a release directory and change its values. The install script (`script/docker/software/`) installs the latest Cosyses release, so routines the image needs must be released first.

## Container init

`script/docker/cosyses.sh` is the entrypoint. It runs the scripts in `/usr/local/lib/start` in order (fixing bind mount owners, `cosyses update`, the SSH server), then waits, and runs `/usr/local/lib/stop` when the container stops. `started.sh` tells Anodosys when a container is up. In `/usr/local/etc/.anodosys`, `NO_COSYSES_UPDATE` and `NO_SSH_SERVER` turn off the update and the SSH server on start.
