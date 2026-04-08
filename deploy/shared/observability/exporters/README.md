# Exporter Configuration Examples

These examples document the expected exporter placement by machine role.

Recommended placement:

- VM1 data: `node_exporter`, `postgres_exporter`, MinIO native metrics, optional `cadvisor`
- VM2 backend: `node_exporter`, optional `cadvisor`, optional `blackbox_exporter`
- VM3 CMS: `node_exporter`, `nginx-prometheus-exporter`, optional `cadvisor`
- Players: direct app scrape only by default; host exporters only where explicitly approved

Files in this directory are examples and snippets only. They intentionally avoid site IPs, secrets, and organization-specific values.
