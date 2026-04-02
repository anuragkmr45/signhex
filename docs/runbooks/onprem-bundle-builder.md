# On-Prem Runtime Bundle Builder

Start here for platform bundle generation.

- QA runbook: `docs/runbooks/onprem-qa-setup.md`
- production runbook: `docs/runbooks/onprem-production-setup.md`

The canonical workflow is artifact-driven:

- backend image archive in
- CMS build archive in
- player installers in
- runtime bundle out

Target QA and production machines receive only generated runtime folders, image archives, configs, and start scripts.

## Primary Command

Run from the `signhex-platform` repo root:

```bash
bash scripts/bundle/assemble-runtime-bundle.sh <site-name>
```

Default behavior:

- generates both `qa/` and `production/`
- consumes released backend, CMS, and player artifacts
- stages runtime-only QA and production folders
- writes `SHA256SUMS.txt`, `verify-bundle.sh`, and `BUNDLE_OVERVIEW.md`

## Required Artifact Inputs

- `BACKEND_IMAGE_REF`
- `BACKEND_IMAGE_ARCHIVE`
- `CMS_BUNDLE_SOURCE`
- `PLAYER_ARTIFACTS_DIR`

`CMS_BUNDLE_SOURCE` may be:

- a CMS `dist/` directory
- a tar-compatible archive of the CMS build output

`PLAYER_ARTIFACTS_DIR` must contain:

- one Windows `.exe`
- one Ubuntu `.deb`
- optional Ubuntu `.AppImage`

## Required Environment Inputs

- `QA_HOST` for `qa` and `all`
- `CMS_PUBLIC_HOST`, `BACKEND_PRIVATE_HOST`, `BACKEND_DEVICE_HOST`, `DATA_PRIVATE_HOST` for `production` and `all`

## Profiles

Generate QA only:

```bash
bash scripts/bundle/assemble-runtime-bundle.sh --profile qa <site-name>
```

Generate production only:

```bash
bash scripts/bundle/assemble-runtime-bundle.sh --profile production <site-name>
```

Validate bundle structure without exporting base images:

```bash
bash scripts/bundle/assemble-runtime-bundle.sh --skip-docker <site-name>
```

Do not deploy a bundle that contains `*.SKIPPED.txt`.

## Example

```bash
QA_HOST=10.30.0.40 \
CMS_PUBLIC_SCHEME=https \
CMS_PUBLIC_HOST=10.20.0.30 \
BACKEND_PRIVATE_HOST=10.20.0.20 \
BACKEND_DEVICE_HOST=10.20.0.21 \
DATA_PRIVATE_HOST=10.20.0.10 \
BACKEND_IMAGE_REF=ghcr.io/hexmon/signhex-server:1.2.3 \
BACKEND_IMAGE_ARCHIVE=/artifacts/signhex-server-1.2.3.tar \
CMS_BUNDLE_SOURCE=/artifacts/signhex-nexus-core-1.2.3.tgz \
PLAYER_ARTIFACTS_DIR=/artifacts/signage-screen/1.2.3 \
bash scripts/bundle/assemble-runtime-bundle.sh site-a
```

## Output Layout

```text
dist/onprem/<site-name>/
  qa/
    backend/
    cms/
    electron/
    QA_SETUP_GUIDE.md
  production/
    data/
    backend/
    cms/
    electron/
    PRODUCTION_SETUP_GUIDE.md
  SHA256SUMS.txt
  verify-bundle.sh
  BUNDLE_OVERVIEW.md
  PROXMOX_SIZING.md
```

Always verify before copying:

```bash
cd dist/onprem/<site-name>
./verify-bundle.sh
```

## Transition Helper

For a temporary local workspace that still contains sibling product repos next to `signhex-platform`, use:

```bash
bash scripts/bundle/workspace-build-bundle.sh <site-name>
```

That wrapper is for build-time convenience only. The supported platform contract remains artifact-driven.
