# Signhex QA Setup Guide

This is the primary QA deployment runbook for support teams.

Use this guide when you need a source-free QA deployment with:

- one QA machine running CMS + backend + PostgreSQL + MinIO
- separate player machines on the same Wi-Fi or LAN
- CMS served at `http://<qa-ip>`
- player devices pointing directly to `http://<qa-ip>:3000`

Generated QA bundle layout:

- `qa/backend/`
- `qa/cms/`
- `qa/electron/`

## 1. Before You Start

### Required inputs

- `SITE_NAME`
- `QA_HOST`
- `BACKEND_IMAGE_REF`
- `BACKEND_IMAGE_ARCHIVE`
- `CMS_BUNDLE_SOURCE`
- `PLAYER_ARTIFACTS_DIR`

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

## 2. Build The QA Bundle

Run on the build machine:

```bash
export SITE_NAME="site-a-qa"
export QA_HOST="10.30.0.40"
export BACKEND_IMAGE_REF="ghcr.io/hexmon/signhex-server:1.2.3"
export BACKEND_IMAGE_ARCHIVE="/artifacts/signhex-server-1.2.3.tar"
export CMS_BUNDLE_SOURCE="/artifacts/signhex-nexus-core-1.2.3.tgz"
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

- if the command says required artifacts are missing, verify `BACKEND_IMAGE_ARCHIVE`, `CMS_BUNDLE_SOURCE`, and `PLAYER_ARTIFACTS_DIR`

## 3. Check The QA Bundle

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

## 4. Copy The QA Runtime Folders

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

## 5. Start The QA Services

### Start backend + PostgreSQL + MinIO

Run on the QA host:

```bash
cd "/opt/signhex/${SITE_NAME}/releases/${RELEASE_ID}/backend"
./load-images.sh
./start.sh
./health-check.sh
docker compose --env-file .env.qa ps
```

Expected result:

- PostgreSQL, MinIO, and backend are healthy

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

## 6. QA Validation

Open:

```text
http://<qa-ip>
```

Confirm:

- login works
- dashboard loads
- API calls succeed through the same origin
- socket-driven UI areas connect

## 7. Player Handoff For QA

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

## 8. Troubleshooting

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

## 9. QA Quick Start

```bash
export SITE_NAME="site-a-qa"
export QA_HOST="10.30.0.40"
export BACKEND_IMAGE_REF="ghcr.io/hexmon/signhex-server:1.2.3"
export BACKEND_IMAGE_ARCHIVE="/artifacts/signhex-server-1.2.3.tar"
export CMS_BUNDLE_SOURCE="/artifacts/signhex-nexus-core-1.2.3.tgz"
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
