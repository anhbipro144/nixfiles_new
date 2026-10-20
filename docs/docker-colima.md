# Docker with Colima on Apple Silicon

`macos.nix` imports `colima.nix` only for the macOS Home Manager target. The
existing flake lock pins Colima, Lima, Docker, Compose and Buildx. Docker Desktop,
a system Docker daemon and `brew services` are unnecessary.

## Configuration and activation

`colima.nix` declares a native `aarch64` Linux VM using Apple's Virtualization
framework (`vz`) and `virtiofs`: 4 CPUs, 6 GiB RAM and a 60 GiB sparse data disk.
Only `~/persona` is shared writable with the VM. Keep development projects there
or add another explicit `--mount` argument. Kubernetes, SSH agent forwarding and
Rosetta and host SSH configuration modification are disabled. Colima must not
rewrite Home Manager's managed `~/.ssh/config`; use `colima ssh` for VM access.
Prefer ARM64 or multi-platform images; AMD64-only workloads
need a deliberate emulation configuration change.

Activate from this repository, making the new module visible to the Git flake
first (no commit is required):

```sh
git add -N colima.nix
home-manager switch --flake "git+file://$HOME/.config/home-manager?submodules=1#neo@mac"
```

Home Manager's `org.nix-community.home.colima` launch agent starts Colima at
graphical login and retries failures every 30 seconds. Its explicit environment
and Nix store paths also work without an interactive shell. On the first start,
Colima downloads its Linux image and runtime, so Docker readiness can take a few
minutes. Check `docker info` before starting project services.

Settings are passed on each supervised start with `--save-config`. Colima owns
the writable `~/.colima/default/colima.yaml` and its VM data; do not make that file
a Nix store symlink. Edit `colima.nix`, activate, and restart the agent to apply
settings to a running VM. Architecture, runtime, VM type and mount type cannot be
changed on an existing VM. Never delete a VM or its data to apply ordinary edits.

Docker's Nix package includes Compose and Buildx. Colima selects the mutable
`colima` Docker context at startup. `~/.docker/config.json` stays writable for
`docker login` and context changes. No global `DOCKER_HOST` is set. SDKs that do
not understand Docker contexts can receive it for a single command:

```sh
DOCKER_HOST="unix://$HOME/.colima/default/docker.sock" your-command
```

## Daily operation

```sh
colima status
docker context show                    # colima
docker info
docker compose version
docker buildx version
docker run --rm hello-world
```

Manage the supervisor when stopping/restarting the VM; an enabled agent otherwise
restarts a stopped foreground process. Booting out sends SIGTERM to Colima's
foreground process, allowing up to 120 seconds for a clean VM shutdown:

```sh
# Stop until the next login or Home Manager activation.
launchctl bootout "gui/$(id -u)/org.nix-community.home.colima"
colima stop

# Start again (after bootout).
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/org.nix-community.home.colima.plist"
```

To restart after editing VM settings, use that stop/start sequence. To suppress
startup permanently, disable the agent in `colima.nix` and activate.

Logs are `~/.local/state/colima/stdout.log` and `stderr.log`. If Docker cannot
connect, inspect `colima status`, `docker context ls`, the logs, and:

```sh
launchctl print "gui/$(id -u)/org.nix-community.home.colima"
docker --context colima info
```

Unset inherited `DOCKER_HOST`/`DOCKER_CONTEXT` overrides if they point at another
engine. Do not symlink `/var/run/docker.sock`; use the context or per-command
socket setting. Changing the flake's packages needs the usual Home Manager
activation; a Colima guest Docker upgrade is a separate `colima update` operation.

## tiemdosime-bot

The existing project runs application processes on macOS and uses
`infra/docker-compose.yml` for PostgreSQL 16 Alpine and Redis 7 Alpine. Both
images support ARM64. The project's existing scripts work unchanged:

```sh
cd "$HOME/persona/hustle/tiemdosime-bot"
docker compose -f infra/docker-compose.yml config --quiet
docker compose -f infra/docker-compose.yml up -d  # same as pnpm infra:up
docker compose -f infra/docker-compose.yml ps
docker compose -f infra/docker-compose.yml exec -T postgres \
  pg_isready -U postgres -d shop_ai
docker compose -f infra/docker-compose.yml exec -T redis redis-cli ping
```

Host applications connect to `localhost:5432` and `localhost:6379`. Containers use
Compose service names `postgres:5432` and `redis:6379`; `localhost` inside a
container refers to that container. PostgreSQL data is in `infra/postgres-data`
and Redis data in `infra/redis-data` on the host, shared through virtiofs. The
project's `restart: unless-stopped` brings running services back when the VM
starts again. `pnpm infra:down` removes the containers but preserves those data
directories. Do not delete these directories during troubleshooting. Redis
durability still depends on the project's Redis persistence configuration.

The project's `infra/docker-compose.yml` binds both published ports to
`127.0.0.1`, keeping PostgreSQL's development password and unauthenticated Redis
off the LAN. This is a two-line change in that separate project repository;
preserve it when moving this setup to another machine. Port conflicts on the
Mac must be resolved before starting the stack.

For the application itself, follow the project's README (`pnpm install`, local
`.env`, Prisma generation/migrations, then `pnpm dev`). Runtime secrets remain
outside this Nix repository and the Nix store.

## Verification

Verified live on 2026-10-18, macOS 26.6, native ARM64, 32 GiB RAM:

| Check | Result |
| --- | --- |
| Build `neo@mac` activation package | Passed, existing lockfile unchanged |
| Activate and repeat the same activation | Both passed; SSH config remained Home Manager managed |
| Launch agent plist and runtime | Valid plist, running job, 120-second shutdown grace |
| Colima / Lima | 0.10.3 / 2.2.0, VZ, aarch64, virtiofs |
| Docker client / guest engine | 29.8.1 / 29.5.2; API connection passed |
| Compose / Buildx | 5.6.0 / 0.35.0; plugins discovered without extra configuration |
| ARM64 `hello-world` | Pulled and ran successfully |
| Buildx build, load and run | Alpine build copied a local file, ran an assertion, printed its marker |
| Bind mounts | Container read a host file and wrote a marker verified on macOS |
| Container networking | DNS lookup and outbound HTTPS passed |
| Project Compose configuration and `pnpm infra:up` | Passed; both services running |
| PostgreSQL / Redis | PostgreSQL 16.15 on aarch64 accepted SQL; Redis returned `PONG` |
| Host connectivity | PostgreSQL protocol handshake and Redis `PING` passed at both `localhost` and `127.0.0.1` |
| Host exposure | `lsof` confirmed only `127.0.0.1:5432` and `127.0.0.1:6379` listeners |
| VM stop/start | Documented launchctl sequence passed; Compose services restarted automatically |
| Data persistence | PostgreSQL test row and explicitly saved Redis key survived VM stop/start |
| Repository whitespace checks | Passed for the Nix repo and touched project Compose file |

The temporary test database, Redis key, test image and host marker files were
removed. PostgreSQL and Redis remain running for development. Redis was explicitly
saved for the persistence check; this does not enable AOF or change the project's
normal Redis durability policy.

The active generation is
`/nix/store/5dyppg63c4i4xva5mcaslm0gjppasl04-home-manager-generation`. The initial
SSH conflict was corrected by disabling `--ssh-config`; a backup containing only
Colima's added include line is at `~/.ssh/config.before-colima-home-manager`.
The original managed SSH configuration is restored.

No application dependencies, `.env`, Prisma migrations, application builds or
external bot integrations were run. Full logout/login, reboot and sleep/wake
were not exercised; login startup was verified by loading the actual launch
agent and testing its VM lifecycle. Registry authentication and AMD64 workloads
were not tested.

Implementation references: [Colima configuration](https://colima.run/docs/configuration/),
[pinned Colima start flags](https://github.com/abiosoft/colima/blob/v0.10.3/cmd/start.go),
and [Home Manager launchd options](https://nix-community.github.io/home-manager/options/home-manager/launchd.html).
