# Product Export Packaging

Use this runbook when you want source-free, per-product deliverables from a build machine.

Generated outputs:

- `out/<release>/server/`
- `out/<release>/cms/`
- `out/<release>/electron/<platform>/`

These outputs are source-free. They are the operator-facing runtime or delivery folders, not development builds.

## Primary command

Run from `signhex-platform`:

```bash
bash scripts/export/package-all.sh --release 2026-04-02-r1 --electron-platform linux
```

## Per-product commands

Server:

```bash
bash scripts/export/package-server.sh --release 2026-04-02-r1
```

CMS:

```bash
bash scripts/export/package-cms.sh --release 2026-04-02-r1
```

Electron:

```bash
bash scripts/export/package-electron.sh --release 2026-04-02-r1 --platform linux
```

## Build-machine expectations

- server export requires Docker on the build machine
- CMS export requires Docker on the build machine
- Electron export is native-host oriented:
  - `--platform macos` requires a macOS builder
  - `--platform linux` requires a Linux builder
  - `--platform windows` requires a Windows builder
- unsupported host/target combinations fail fast instead of attempting unreliable cross-builds

## Output layout

- `out/<release>/server/`
  - Docker image archives for `api`, `postgres`, and `minio`
  - `docker-compose.yml`
  - `.env.template`
  - `load-images.sh`, `init-env.sh`, `start.sh`, `stop.sh`, `update.sh`, `health-check.sh`
- `out/<release>/cms/`
  - Docker image archive for `nginx`
  - built static assets in `www/`
  - rendered-config template in `nginx/default.conf.template`
  - `docker-compose.yml`
  - `.env.template`
  - `load-images.sh`, `init-env.sh`, `render-config.sh`, `start.sh`, `stop.sh`, `update.sh`, `health-check.sh`
- `out/<release>/electron/<platform>/`
  - packaged installers only
  - `config.example.json`
  - `README.md`
  - `SHA256SUMS.txt`

## Relationship To QA / Production Bundles

Preferred flow:

1. generate `server/` and `cms/` exports from this runbook
2. gather player installers into one staging directory
3. feed those paths into `scripts/bundle/assemble-runtime-bundle.sh`

Example:

```bash
bash scripts/export/package-server.sh --release 2026-04-02-r1
bash scripts/export/package-cms.sh --release 2026-04-02-r1

SERVER_PACKAGE_DIR="out/2026-04-02-r1/server" \
CMS_PACKAGE_DIR="out/2026-04-02-r1/cms" \
PLAYER_ARTIFACTS_DIR="/artifacts/signage-screen/2026-04-02-r1" \
bash scripts/bundle/assemble-runtime-bundle.sh --profile qa site-a-qa
```

`PLAYER_ARTIFACTS_DIR` must contain at least:

- one Windows `.exe`
- one Ubuntu `.deb`
- optional Ubuntu `.AppImage`

The per-platform `electron/<platform>/` exports are for direct delivery to target player machines. If you want to use them as bundle inputs, collect the required Windows and Ubuntu installers into a single `PLAYER_ARTIFACTS_DIR` first.

## Operator commands on target hosts

Server package:

```bash
cp .env.template .env
# edit .env
# place certs/ca.crt
./load-images.sh
./start.sh
./health-check.sh
```

CMS package:

```bash
cp .env.template .env
# edit BACKEND_UPSTREAM_HOST and BACKEND_UPSTREAM_PORT if needed
./init-env.sh
./load-images.sh
./start.sh
./health-check.sh
```

Update flow:

```bash
# copy the previous .env into the new release folder
./load-images.sh
./update.sh
./health-check.sh
```

## Operator contract

- target machines receive only generated output folders
- target machines do not need product source repos
- secrets are supplied at runtime through `.env` and cert files
- persistent data remains outside release folders

## Environment bundle relationship

The QA and production environment bundler remains supported. It should consume these exported packages instead of raw sibling repos whenever possible.
