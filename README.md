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

## Primary Commands

Canonical artifact-driven bundle assembly:

```bash
bash scripts/bundle/assemble-runtime-bundle.sh <site-name>
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

- bundle workflow: `docs/runbooks/onprem-bundle-builder.md`
- QA deployment: `docs/runbooks/onprem-qa-setup.md`
- production deployment: `docs/runbooks/onprem-production-setup.md`

## Commit Rules

- do not commit generated bundles
- do not commit secrets, certificates, or real `.env` values
- commit only templates, placeholder READMEs, and reusable operational assets
