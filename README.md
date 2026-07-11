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

- **`--privileged`** (or `--sysctl vm.overcommit_memory=1`) is recommended: the
  start script tries to set `vm.overcommit_memory=1` and raise the open-files
  limit, but degrades gracefully without it.
- **Persist data** by mounting a volume at `/srv/data/redis` (see below).

```
docker run --rm --privileged -p 6379:6379 -v redis-data:/srv/data/redis crbrdocker/redis
```

## Configuration & data

- **Config file** — baked at **`/etc/redis/redis.conf`** (defaults: `maxmemory 2gb`,
  `maxmemory-policy volatile-lru`, `appendonly yes`, `protected-mode no`,
  `daemonize no`, `logfile ""` → stdout, `dir /srv/data/redis`, …). Override the
  whole file by mounting your own on top of it:
  ```
  docker run -v ./redis.conf:/etc/redis/redis.conf:ro ... crbrdocker/redis
  ```
- **Data directory** — **`/srv/data/redis`** (the `dir` in the config — RDB dump +
  AOF). Declared as a `VOLUME`; mount a host path or named volume there to persist
  across container recreation (an anonymous volume is used if you mount nothing):
  ```
  docker run -v redis-data:/srv/data/redis ... crbrdocker/redis
  ```
- **Logs** — container **stdout** (`logfile ""`), so `docker logs` shows them.

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
