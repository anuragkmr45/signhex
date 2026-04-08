# Security And Access Standard

## Metrics Endpoint Exposure

- Do not expose Prometheus targets through the public CMS entrypoint.
- Bind metrics endpoints to private management interfaces or localhost where possible.
- Keep direct player scrape optional and config-gated.
- Default to allowlisted private-network HTTP unless internal policy requires TLS or mTLS.

## Authentication And Browser Traffic

- Browsers must not talk to Prometheus directly.
- CMS uses backend summary APIs for product-facing views.
- Grafana is exposed through the CMS reverse proxy on `/grafana/`.

## Grafana Access Model

- Grafana is operator-facing historical drill-down, not the system of record for current product state.
- Same-origin reverse proxying is the default model.
- RBAC and session decisions must be explicit in later phases; Phase 1 only establishes the reverse-proxy path and provisioning model.

## Secrets

- Do not commit secrets, certificates, or real `.env` values.
- Monitoring credentials and alert destinations must be injected at deploy time.
