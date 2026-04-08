# Production Observability Deployment Notes

Production observability follows the fixed VM layout:

- VM1 data: exporters and native MinIO metrics
- VM2 backend: Prometheus, optional Alertmanager, backend `/metrics`, VM exporters
- VM3 CMS: Grafana behind the CMS reverse proxy on `/grafana/`

Primary inputs:

- use `bundle.env.example` as the starting point for site-specific observability values
- maintain player direct-scrape targets in the Prometheus `file_sd` inventory only if direct scrape is approved
- keep site IPs and secrets outside git-tracked files
- keep Alertmanager outbound receiver settings site-local; the base config is local-only by default
- keep Prometheus retention aligned to VM2 storage sizing; the baseline target is 30 days with WAL compression enabled

The canonical shared assets live in `deploy/shared/observability/`.
