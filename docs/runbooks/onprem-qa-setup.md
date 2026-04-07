# Signhex QA Setup Guide

This is the primary QA deployment runbook for support teams.

Use this guide when you need a source-free QA deployment with:

- one QA machine running CMS + backend bundle + PostgreSQL + MinIO
- separate player machines on the same Wi-Fi or LAN
- CMS served at `http://<qa-ip>`
- player devices pointing directly to `http://<qa-ip>:3000`

Preferred build flow:

1. generate `server/` and `cms/` product exports from `docs/runbooks/product-export-packaging.md`
2. gather the required player installers into `PLAYER_ARTIFACTS_DIR`
3. assemble the QA runtime bundle from those inputs

Generated QA bundle layout:

- `qa/backend/`
- `qa/cms/`
- `qa/electron/`

The generated `qa/backend/` compose file starts two backend containers from the same image:

- `api` for HTTP/socket traffic on `3000`
- `worker` for pg-boss handlers, media processing, telemetry persistence, and other background jobs

## 1. Before You Start

### Required inputs

- `SITE_NAME`
- `QA_HOST`
- preferred:
  - `SERVER_PACKAGE_DIR`
  - `CMS_PACKAGE_DIR`
- fallback:
  - `BACKEND_IMAGE_REF`
  - `BACKEND_IMAGE_ARCHIVE`
  - `CMS_BUNDLE_SOURCE`
- `PLAYER_ARTIFACTS_DIR`

`PLAYER_ARTIFACTS_DIR` must contain the Windows and Ubuntu player installers to stage into `qa/electron/`.

### Required tools on the build machine

Run:

```bash
docker info >/dev/null && echo "Docker OK"
tar --version | head -n 1
openssl version
bash scripts/bundle/assemble-runtime-bundle.sh --help | sed -n '1,80p'
```

Expected result:

- Docker, tar, openssl, and the bundle help output are all available

## 2. Build Or Gather Product Packages

Preferred build-machine flow:

```bash
export RELEASE_ID="2026-04-02-r1"

bash scripts/export/package-server.sh --release "$RELEASE_ID"
bash scripts/export/package-cms.sh --release "$RELEASE_ID"
```

QA layout note:

- keep the default server export layout for QA
- `package-server.sh` defaults to `--deployment-layout standalone`
- do not use `--deployment-layout production-split` for the single-host QA topology in this runbook

Expected result:

- `out/$RELEASE_ID/server/`
- `out/$RELEASE_ID/cms/`

Player installer note:

- gather the Windows `.exe` and Ubuntu `.deb` into one `PLAYER_ARTIFACTS_DIR`
- the per-platform `electron/<platform>/` exports are for direct device delivery, not a combined QA bundle input by themselves

## 3. Build The QA Bundle

Run on the build machine:

```bash
export SITE_NAME="site-a-qa"
export RELEASE_ID="2026-04-02-r1"
export QA_HOST="10.30.0.40"
export SERVER_PACKAGE_DIR="out/${RELEASE_ID}/server"
export CMS_PACKAGE_DIR="out/${RELEASE_ID}/cms"
export PLAYER_ARTIFACTS_DIR="/artifacts/signage-screen/1.2.3"

bash scripts/bundle/assemble-runtime-bundle.sh --profile qa "$SITE_NAME"
```

Purpose:

- assembles the QA runtime bundle from released artifacts
- stages runtime-only QA folders
- copies prebuilt Windows and Ubuntu player installers

Expected result:

- the command ends with `Bundle created at: .../dist/onprem/<site-name>`

Failure hint:

- if the command says required artifacts are missing, verify `SERVER_PACKAGE_DIR`, `CMS_PACKAGE_DIR`, and `PLAYER_ARTIFACTS_DIR`

## 4. Check The QA Bundle

Run:

```bash
cd "dist/onprem/$SITE_NAME"
./verify-bundle.sh
find qa -maxdepth 2 -type f | sort
```

Expected result:

- checksum validation succeeds
- the bundle contains:
  - `qa/backend/`
  - `qa/cms/`
  - `qa/electron/`

## 5. Copy The QA Runtime Folders

Choose a release ID and target host:

```bash
export RELEASE_ID="2026-03-30-r1"
export DEPLOY_USER="support"
export QA_VM_HOST="10.30.0.40"
```

Copy the QA folders:

```bash
scp -r "dist/onprem/${SITE_NAME}/qa/backend" "${DEPLOY_USER}@${QA_VM_HOST}:/opt/signhex/${SITE_NAME}/releases/${RELEASE_ID}/"
scp -r "dist/onprem/${SITE_NAME}/qa/cms" "${DEPLOY_USER}@${QA_VM_HOST}:/opt/signhex/${SITE_NAME}/releases/${RELEASE_ID}/"
```

Purpose:

- copies only runtime folders to the QA host

Expected result:

- no repository checkout is needed on the QA machine

## 6. Start The QA Services

### Start backend bundle + PostgreSQL + MinIO

Run on the QA host:

```bash
cd "/opt/signhex/${SITE_NAME}/releases/${RELEASE_ID}/backend"
./load-images.sh
./start.sh
./health-check.sh
docker compose --env-file .env.qa ps
```

Expected result:

- PostgreSQL and MinIO are healthy
- both `api` and `worker` containers are running in `docker compose ps`

### Start CMS

Run on the QA host:

```bash
cd "/opt/signhex/${SITE_NAME}/releases/${RELEASE_ID}/cms"
./load-images.sh
./start.sh
./health-check.sh
docker compose --env-file .env.qa ps
curl -fsS "http://127.0.0.1/"
curl -fsS "http://127.0.0.1/api/v1/health"
```

Expected result:

- CMS loads over HTTP
- same-origin proxying to backend works

## 7. QA Validation

Open:

```text
http://<qa-ip>
```

Confirm:

- login works
- dashboard loads
- API calls succeed through the same origin
- socket-driven UI areas connect

## 8. Player Handoff For QA

Give the device team:

```text
qa/electron/
```

Minimum workflow:

1. Install the Windows or Ubuntu player from `installers/`
2. Copy `config.example.json`
3. Keep `runtime.mode` as `qa`
4. Pair the device against `http://<qa-ip>:3000`
5. Confirm the device appears in the QA CMS

## 9. Troubleshooting

### CMS loads but API calls fail

Run on the QA host:

```bash
cd "/opt/signhex/${SITE_NAME}/releases/${RELEASE_ID}/cms"
curl -fsS "http://127.0.0.1/api/v1/health"
docker compose --env-file .env.qa logs --tail=200
```

Check:

- backend stack is healthy
- QA host firewall allows `3000/tcp`
- `nginx/default.conf` points to the correct QA host IP

### Players cannot connect

Run on the QA host:

```bash
cd "/opt/signhex/${SITE_NAME}/releases/${RELEASE_ID}/backend"
curl -fsS "http://127.0.0.1:3000/api/v1/health"
ss -ltn | grep 3000
```

Check:

- players use the QA host IP, not the CMS URL
- QA network allows player access to `3000/tcp`

### Bundle is not deployment-ready

Run on the build machine:

```bash
find "dist/onprem/${SITE_NAME}" -name '*.SKIPPED.txt' -print
```

If any files are found:

- rebuild without `--skip-docker`

## 10. QA Quick Start

```bash
export RELEASE_ID="2026-04-02-r1"
export SITE_NAME="site-a-qa"
export QA_HOST="10.30.0.40"
bash scripts/export/package-server.sh --release "$RELEASE_ID"
bash scripts/export/package-cms.sh --release "$RELEASE_ID"

export SERVER_PACKAGE_DIR="out/${RELEASE_ID}/server"
export CMS_PACKAGE_DIR="out/${RELEASE_ID}/cms"
export PLAYER_ARTIFACTS_DIR="/artifacts/signage-screen/1.2.3"

bash scripts/bundle/assemble-runtime-bundle.sh --profile qa "$SITE_NAME"
cd "dist/onprem/$SITE_NAME"
./verify-bundle.sh

scp -r "qa/backend" support@10.30.0.40:/opt/signhex/site-a-qa/releases/2026-03-30-r1/
scp -r "qa/cms" support@10.30.0.40:/opt/signhex/site-a-qa/releases/2026-03-30-r1/
```

Then on the QA host:

```bash
cd /opt/signhex/site-a-qa/releases/2026-03-30-r1/backend
./load-images.sh
./start.sh
./health-check.sh

cd /opt/signhex/site-a-qa/releases/2026-03-30-r1/cms
./load-images.sh
./start.sh
./health-check.sh
```
