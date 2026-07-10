# redis

Minimal **redis** image built on top of the crbr Debian base
(`crbrdocker/debian:stable`), multi-arch (`amd64` + `arm64`), published by CI to
**GHCR** (`ghcr.io/crbrdocker/redis`) and **Docker Hub** (`crbrdocker/redis`).
Rebuilt weekly, but only when something changed. The previous manual
implementation is archived verbatim under `OLD/`.

## Usage

```
docker run --rm -p 6379:6379 crbrdocker/redis
```

- **Persistent data** lives in the volume **`/srv/data/redis`** (the DB — RDB +
  AOF). If nothing is mounted, an anonymous volume is created automatically;
  mount a host path or named volume to persist across container recreation.
- **`--privileged`** (or `--sysctl vm.overcommit_memory=1`) is recommended: the
  start script tries to set `vm.overcommit_memory=1` and raise the open-files
  limit, but degrades gracefully without it.

```
docker run --rm --privileged -p 6379:6379 -v redis-data:/srv/data/redis crbrdocker/redis
```

Config baked at `/etc/redis/redis.conf` (`maxmemory 2gb`,
`maxmemory-policy volatile-lru`, `appendonly yes`, …); override by replacing that
file. Logs go to `/srv/log/redis` and are cleared on each start.

## How it is built

Everything is driven by `.github/workflows/build.yml`:

1. **prep** — lowercases the registry owner (OCI rejects uppercase).
2. **gate** — `need_rebuild.sh` decides whether a rebuild is warranted.
3. **build** — matrix `arch × {amd64→ubuntu-24.04, arm64→ubuntu-24.04-arm}`,
   **native, no QEMU**; `docker buildx build` pushes an OCI `:latest-<arch>`
   image (with provenance + SBOM) to both registries.
4. **manifest** — merges the per-arch tags into `:latest` via
   `docker buildx imagetools create`.
5. **cleanup** — prunes untagged GHCR versions.

Triggers: any push to `main`, weekly `cron 20 8 * * 2`, or manual *Run
workflow* (with a `force` toggle, default on, to build even when the gate sees
no change).

### Rebuild gate

`need_rebuild.sh <image-ref> [vcs-ref] [base-image]` prints `REBUILD=true|false`.
It rebuilds when the published image is missing, its
`org.opencontainers.image.revision` label ≠ HEAD, the base `:stable` digest it
was built on has changed, or a simulated `dist-upgrade` shows pending updates.

## Registries & secrets

- GHCR uses the built-in `GITHUB_TOKEN` (needs `packages: write`) — no secret.
- Docker Hub is conditional on secrets `DOCKERHUB_USERNAME` + `DOCKERHUB_TOKEN`;
  namespace is repo/org var `DOCKERHUB_NAMESPACE` (falls back to the username).
  Absent creds → GHCR-only.
