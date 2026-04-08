# Observability Target Inventory And Networking

## Player Target Inventory

- Use Prometheus `file_sd` for optional direct player scrape.
- Keep the inventory in a site-local rendered file derived from `players.targets.example.json`.
- Maintain only stable labels: `site`, `environment`, `device_id`, `screen_id`, and an optional bounded grouping label.
- Direct player scrape requires the player config to opt into remote metrics exposure. The safe default remains `bindAddress=127.0.0.1` with `allowRemoteAccess=false`.

## VM Networking

Required reachability:

- VM2 Prometheus to VM1 exporters and MinIO metrics
- VM2 Prometheus to VM2 local exporters and backend `/metrics`
- VM2 Prometheus to VM3 exporters and Grafana metrics if enabled
- VM3 nginx to local Grafana on `/grafana/`
- VM3 CMS reverse proxy to VM2 backend `/api/v1/` and `/socket.io/`

## Firewall Guidance

- Allow only the minimum management-plane ingress required for exporters and Prometheus.
- Do not expose exporter ports through the public CMS entrypoint.
- If player direct scrape is not approved, keep player metrics bound to localhost.
