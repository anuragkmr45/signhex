# QA Observability Deployment Notes

QA uses the same VM1 / VM2 / VM3 topology pattern as production.

- QA VM1 data: exporters and native MinIO metrics
- QA VM2 backend: Prometheus, optional Alertmanager, backend `/metrics`, VM exporters
- QA VM3 CMS: Grafana behind `/grafana/`

The QA topology intentionally mirrors production so observability assets, runbooks, and promotions stay aligned.

Operational notes:

- keep Alertmanager outbound receiver settings site-local; the base config is local-only by default
- keep Prometheus retention aligned to the QA VM2 storage budget; the baseline target is 30 days with WAL compression enabled
- validate direct player scrape targets in QA before enabling them in production
