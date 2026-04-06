# Signhex Platform

`signhex-platform` is the master repository for platform operations, deployment, support, architecture, and release orchestration across the Signhex product suite.

## Scope

This repo owns:

- QA and production deployment runbooks
- support runbooks and troubleshooting playbooks
- environment topology and architecture docs
- release manifests
- shared operational scripts
- repository and access-control standards
- non-product-code assets

This repo does **not** own product source code. Product code remains in:

- `signhex-server`
- `signhex-nexus-core`
- `signage-screen`

## Key Rule

This repo is **artifact-driven**, not source-driven.

- no Git submodules
- no source vendoring
- no nested repos
- no requirement for ops/support to clone product repos

The canonical bundle assembler consumes released artifacts:

- backend image archive
- CMS build archive
- player installers

This repo also owns the source-protected product export flow:

- `out/<release>/server/`
- `out/<release>/cms/`
- `out/<release>/electron/<platform>/`

Notes:

- `server/` and `cms/` exports are direct inputs to the runtime bundle assembler
- `electron/<platform>/` exports are per-platform distributables for device delivery
- QA/production bundle assembly still expects `PLAYER_ARTIFACTS_DIR` to contain the Windows and Ubuntu installers you want staged into environment bundles

## Primary Commands

Product export packaging:

```bash
bash scripts/export/package-all.sh --release 2026-04-02-r1 --electron-platform linux
```

Split-production variant:

```bash
bash scripts/export/package-all.sh --release 2026-04-02-r1 --electron-platform linux --server-deployment-layout production-split
```

Per-product exports:

```bash
bash scripts/export/package-server.sh --release 2026-04-02-r1
bash scripts/export/package-cms.sh --release 2026-04-02-r1
bash scripts/export/package-electron.sh --release 2026-04-02-r1 --platform linux
```

The plain server export command uses the default `standalone` layout, which is appropriate for QA and other all-in-one server-package workflows.

For the split production layout (`VM1=data`, `VM2=backend`, `VM3=cms`), export the server package with explicit intent:

```bash
bash scripts/export/package-server.sh --release 2026-04-02-r1 --deployment-layout production-split
```

Canonical artifact-driven bundle assembly:

```bash
bash scripts/bundle/assemble-runtime-bundle.sh <site-name>
```

Preferred two-step flow:

```bash
bash scripts/export/package-server.sh --release 2026-04-02-r1 --deployment-layout production-split
bash scripts/export/package-cms.sh --release 2026-04-02-r1

SERVER_PACKAGE_DIR="out/2026-04-02-r1/server" \
CMS_PACKAGE_DIR="out/2026-04-02-r1/cms" \
PLAYER_ARTIFACTS_DIR="/artifacts/signage-screen/2026-04-02-r1" \
bash scripts/bundle/assemble-runtime-bundle.sh site-a
```

Transition wrapper for a local shared workspace that still contains sibling product repos:

```bash
bash scripts/bundle/workspace-build-bundle.sh <site-name>
```

## Repo Layout

```text
docs/        Architecture, environments, runbooks, support, governance
deploy/      Deployment templates and environment assembly files
manifests/   QA/production version pins and release records
scripts/     Bundle assembly, bootstrap, verification, release helpers
standards/   Repository, CI/CD, security, and observability standards
assets/      Diagrams, templates, and non-product support assets
```

## Canonical Runbooks

- product export packaging: `docs/runbooks/product-export-packaging.md`
- bundle workflow: `docs/runbooks/onprem-bundle-builder.md`
- QA deployment: `docs/runbooks/onprem-qa-setup.md`
- production deployment: `docs/runbooks/onprem-production-setup.md`

## Commit Rules

- do not commit generated bundles
- do not commit secrets, certificates, or real `.env` values
- commit only templates, placeholder READMEs, and reusable operational assets
