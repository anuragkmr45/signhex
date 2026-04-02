# Access Control And Ownership

## Repo Ownership

- `signhex-server`: backend team write access
- `signhex-nexus-core`: CMS/frontend team write access
- `signage-screen`: player/electron team write access
- `signhex-platform`: platform, ops, support, and release engineering write access

## Minimum Read Access

- all engineering teams should have read access to `signhex-platform`
- platform/security should have read access to every repo
- ops/support should not need write access to product repos

## Governance Rules

- enable branch protection in every repo
- require owner approval per repo through `CODEOWNERS`
- promote QA and production only through manifest PRs in `signhex-platform`
- do not let ops edit product code repos to change deployment behavior
