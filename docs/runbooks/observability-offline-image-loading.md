# Observability Offline Image Loading

## Purpose

Production runtime is air-gapped. All observability images must be pre-staged as archives or pre-loaded on the target hosts.

## Recommended Images

- Prometheus
- Alertmanager if enabled
- Grafana
- `node_exporter`
- `postgres_exporter`
- `nginx-prometheus-exporter`
- `cadvisor` where used
- optional `blackbox_exporter`

## Loading Procedure

1. Copy the image archives into the target host release folder under `observability/images/`.
2. Run `docker load -i <archive>` for each image, or use the host-specific helper script if one is present.
3. Verify the expected image tags with `docker image ls`.
4. Start the observability containers only after the required images are loaded locally.

## Config-Only Updates

- When only rules, dashboards, or rendered config files change, do not reload unrelated images.
- Re-run `scripts/verify/validate-observability-assets.sh` on the build machine before copying the updated config set.
- Copy only the updated rendered files to the target release folder, then restart the affected service in dependency order:
  1. Alertmanager if its config changed
  2. Prometheus if scrape config or rules changed
  3. Grafana if provisioning or dashboard files changed

## No Runtime Pulls

- Do not run `docker pull` on production targets.
- If an archive is missing, treat that as a packaging or release-preparation failure and correct it before proceeding.
