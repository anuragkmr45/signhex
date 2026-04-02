# Repository Topology

Signhex uses a strict multi-repo platform model.

## Product Repos

- `signhex-server`: backend product code only
- `signhex-nexus-core`: CMS product code only
- `signage-screen`: Electron player product code only

## Platform Repo

- `signhex-platform`: deployment, docs, support, runbooks, architecture, release manifests, shared operational scripts, and standards

## Operating Model

- product teams work in their own repos only
- support and ops work in `signhex-platform`
- `signhex-platform` consumes released artifacts, not product source
- QA and production promotion happens by changing manifest versions in `signhex-platform`

## Why This Model

- least-privilege repo access
- cleaner ownership boundaries
- scalable team structure
- reproducible environment promotion
- no deployment dependence on source checkouts
