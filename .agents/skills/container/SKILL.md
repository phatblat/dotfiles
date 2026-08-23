---
name: container
description: "Apple's native `container` CLI for running Linux containers as lightweight per-container VMs on macOS 26 Apple Silicon. Load when creating, configuring, managing, backing up, sharing, or deleting containers, images, volumes, or networks with `container`; when `container` or `container system start` fails; or when choosing between `container` and Docker/Podman/Colima on a Mac."
---

# container Skill

Apple's `container` runs Linux containers as **lightweight virtual machines**
on macOS. Each container gets its own VM and its own IP — not a shared Linux
VM the way Docker Desktop, Colima, and Podman Machine work. Images are
OCI-compatible, so any registry and any `Dockerfile` still works.

Documented against **container 1.2.2**. Verify with `container --version`; run
`container <command> --help` before relying on flags from a different version.

## When to load

- Building or running Linux containers on macOS without Docker Desktop.
- `container` command failures, or `container system start` not working.
- Backing up, exporting, or sharing images/containers/volumes on macOS.
- Deciding between `container` and Docker/Podman/Colima on Apple Silicon.

## Requirements

- **macOS 26 or later.** Older macOS is unsupported; upstream won't take bug
  reports that don't reproduce on macOS 26.
- **Apple Silicon.** No Intel Macs.

Check with `sw_vers` and `uname -m` before recommending it to anyone.

The CLI installs to `/usr/local/bin`. That directory is on zsh's PATH via
`/etc/paths`, but **nushell does not inherit it** — if `container` is "not
found" in nu while `/usr/local/bin/container --version` works, that's the
cause, not a failed install.

## Mental model

| | `container` | Docker Desktop / Colima / Podman |
| --- | --- | --- |
| Isolation | One lightweight VM **per container** | Many containers share one Linux VM |
| Networking | Each container gets its own vmnet IP | Shared VM network, port-forwarded |
| Host data | Only what you explicitly mount, per container | Whole VM mount, then re-shared inward |
| Daemon | `container system` apiserver (launchd) | Docker daemon / VM lifecycle tool |

Practical consequences: startup is per-container VM boot (fast, but not free);
isolation is stronger than a shared-VM runtime; and **the container's IP is
reachable from the host directly, so `-p` is often unnecessary**. `container
ls` prints the IP (typically on the `192.168.64.0/24` vmnet subnet):

```bash
container run -d --name web nginx:alpine   # note: no -p
container ls                               # → IP 192.168.64.10/24
curl http://192.168.64.10/                 # → 200, straight from the host
```

## Install

Use Apple's signed installer package — it registers the system service,
networking helper, and the update/uninstall scripts. Package managers
(`mise`/`aqua:apple/container`, `nixpkgs#container`) extract only the CLI
binary from that same `.pkg` without running it, so the service components are
missing. `brew install container` does wire up a service, but lags the official
release and is not the supported path.

```bash
gh release download --repo apple/container --pattern '*-installer-signed.pkg' --dir /tmp
pkgutil --check-signature /tmp/container-*-installer-signed.pkg   # expect: Apple Inc. - Containerization, notarized
sudo installer -pkg /tmp/container-*-installer-signed.pkg -target /
container system start --enable-kernel-install                    # see note below
container run --rm alpine echo hello                              # end-to-end check
```

On a **fresh machine there is no default kernel**, and a bare
`container system start` stops to prompt for one — which fails outright in a
non-interactive shell (`Error: failed to read user input`). Pass
`--enable-kernel-install` (or `--disable-kernel-install`) to answer up front;
it fetches the recommended Kata Containers kernel. Subsequent starts don't
prompt.

### Upgrade, downgrade, uninstall

The installer places helper scripts in `/usr/local/bin`, so the package is
self-updating. Always stop the service first.

| Task | Command |
| --- | --- |
| Upgrade to latest | `container system stop && /usr/local/bin/update-container.sh` |
| Install a specific version | `/usr/local/bin/update-container.sh -v 1.2.2` |
| Downgrade | `uninstall-container.sh -k` then `update-container.sh -v <older>` |
| Uninstall, keep user data | `/usr/local/bin/uninstall-container.sh -k` |
| Uninstall, remove user data | `/usr/local/bin/uninstall-container.sh -d` |

Restart with `container system start` afterward. Upstream only guarantees
stability within patch versions, so read the release notes before a minor bump.

## Create

```bash
container run --rm alpine echo hello               # one-shot, auto-removed
container run -it ubuntu:latest /bin/bash          # interactive shell
container run -d --name web -p 8080:80 nginx       # detached, port published
container run -e NODE_ENV=production -c 2 -m 1G node:18
container create --name web nginx && container start web   # create now, start later
```

Resource flags are `-c/--cpus` and `-m/--memory` (K/M/G/T/P suffixes). Other
frequently-wanted flags: `--init` (reap zombies, forward signals), `--rm`,
`-v/--volume`, `--mount type=volume,source=<v>,target=<path>,readonly`,
`--tmpfs`, `--read-only`, `--network <name>[,mac=…]`, `--ssh` (forward the SSH
agent), `--rosetta` (x86 binaries), `--entrypoint`, `--cidfile`.

```bash
container build -t my-app:latest .                 # BuildKit; Dockerfile, else Containerfile
container build -f docker/Dockerfile.prod --build-arg NODE_VERSION=18 -t my-app:prod .
container build --target production --no-cache -t my-app:prod .

container volume create --opt size=10g mydata      # or -s 10g
container network create --subnet 192.168.100.0/24 mynet
```

`container machine` is a different thing from a container: a persistent Linux
VM that mounts your home directory, for when you want a Linux *workstation*
rather than a container.

```bash
container machine create --cpus 4 --memory 8G --set-default alpine:3.22
container machine run                              # interactive login shell
container machine run -n my-machine uname -a
```

## Configure

```bash
container system property list                     # all system properties (toml; --format json)
container system dns create <domain>               # local DNS domain for containers
container system dns list
container system kernel set <path>                 # override the guest kernel

container builder start --cpus 4 --memory 4G       # BuildKit builder resources
container machine set cpus=4 memory=8G             # takes effect after stop/start
container machine set -n my-machine home-mount=ro  # ro | rw | none
container machine set kernel=                      # clear a custom kernel override
```

## Manage

```bash
container ls -a                                    # --all includes stopped
container stop web ; container start web           # no `container restart` exists
container kill -s SIGHUP web                       # default signal is already KILL
container exec -it web /bin/sh
container logs -f web
container inspect web
container stats                                    # live, top-style
container stats --no-stream --format json web      # single snapshot, scriptable

container system status                            # is the apiserver running
container system logs
container system df                                # disk usage
container builder status
container machine ls ; container machine inspect ; container machine logs --boot
```

## Back up

```bash
container image save -o my-app.tar my-app:latest   # image → tar
container image load -i my-app.tar                 # tar → image

container stop mycontainer                         # stop first for a consistent snapshot
container export -o mycontainer.tar mycontainer    # container filesystem → tar

container cp ./config.json web:/etc/app/           # host → container (must be running)
container cp web:/var/log/app.log ./logs/          # container → host
```

**There is no built-in volume backup command.** Mount the volume into a
throwaway container and stream a tar out:

```bash
container run --rm -v mydata:/data alpine tar -cf - -C /data . > mydata-backup.tar
container run --rm -i -v mydata:/data alpine tar -xf - -C /data < mydata-backup.tar
```

## Share

```bash
container registry login ghcr.io -u <user> --password-stdin < token.txt
container registry list                            # stored logins
container image tag my-app:latest ghcr.io/me/my-app:1.0
container image push ghcr.io/me/my-app:1.0
container image pull --platform linux/arm64 ghcr.io/me/my-app:1.0
container registry logout ghcr.io
```

For air-gapped transfer, skip the registry and move a tar with
`container image save` / `container image load`.

Registry scheme defaults to `auto`: HTTP for loopback, RFC1918 addresses, and
hosts under the default container DNS domain; HTTPS otherwise. Force it with
`--scheme http|https`.

## Delete

```bash
container rm web              ; container prune            # stopped containers
container image rm my-app     ; container image prune      # unreferenced images
container volume rm mydata    ; container volume prune     # unused volumes
container network rm mynet    ; container network prune
container builder rm
container machine rm my-machine
```

## Gotchas

- **macOS 26 + Apple Silicon only.** No Intel, no macOS 15 or earlier.
- **No Docker socket and no `docker` CLI compatibility.** Tools that speak the
  Docker API — including `docker-compose` and any `d*` shell wrapper functions
  — do not target `container`. Migrating a Compose stack means rewriting it,
  not repointing a socket.
- **Anonymous volumes are not cleaned up by `--rm`.** Unlike Docker,
  `container run --rm -v /data` leaves an `anon-<uuid>` volume behind. Find
  them with `container volume ls -q | grep anon` and delete them explicitly.
- **`container restart` does not exist** — `container stop` then
  `container start`.
- **stdin is closed unless you pass `-i`.** Piping into a container
  (`… < backup.tar`) without `container run -i` delivers nothing — and
  **exits 0**, so a restore script reports success having written no data.
  Verified: the same restore without `-i` prints `tar: short read` and leaves
  the volume empty.
- **`container machine set` changes need a stop/start** to take effect.
- **Stop a container before `container export`** if you want a consistent
  filesystem snapshot; a running export takes a runtime snapshot instead.
- **Nested virtualization** (`--virtualization`) needs Apple Silicon M3+ and a
  guest kernel built with `CONFIG_KVM=y`.
- Authoritative docs: <https://github.com/apple/container> and its
  `docs/command-reference.md` at the tag matching your installed version.
