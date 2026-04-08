# Observability Stack Install And Upgrade

## Scope

This runbook covers the platform-owned observability stack:

- Prometheus on VM2
- optional Alertmanager on VM2
- Grafana on VM3 behind `/grafana/`
- exporter placement on VM1 / VM2 / VM3

## Install

1. Start from the environment example in `deploy/production/observability/` or `deploy/qa/observability/`.
2. Render the Prometheus, Alertmanager, and Grafana templates with site-specific values.
3. Stage the rendered files into the target host release folders under `observability/`.
4. Load any required image archives before starting containers.
5. Keep the base Alertmanager config local-only unless a site-specific outbound receiver has been reviewed and rendered.
6. Start VM1 exporters first, then VM2 Alertmanager, then VM2 Prometheus, then VM3 Grafana.
7. Confirm Prometheus target health, rule load success, Alertmanager config load success, and Grafana dashboard provisioning.

## Upgrade

1. Copy the previous rendered env files and target inventories into the new release.
2. Replace only the version-pinned image archives and rendered config outputs intended for the new release.
3. Re-run `scripts/verify/validate-observability-assets.sh` before loading the new images.
4. Re-run any site-specific Alertmanager receiver validation after rendering secrets or destinations.
5. Restart Alertmanager and Prometheus before Grafana so datasource and alert health are already available.

## Rollback

1. Stop the observability containers on the affected host.
2. Restore the previous release folder or previous rendered config set.
3. Re-load the previous image archives if the version changed.
4. Start the previous release and validate target health again.

## Operational Notes

- Production and QA should keep Alertmanager running even when outbound notifications are intentionally disabled; this preserves grouping, silences, and a stable alert inspection surface.
- CMS currently shows alert summary posture only. Detailed alert triage, silence management, and notification workflow remain in Grafana and Alertmanager.
- Keep Prometheus retention aligned to the actual VM2 storage budget. The 30-day baseline is a starting point, not a guarantee for undersized disks.

## Environment Notes

- Production and QA share the same VM1 / VM2 / VM3 structure.
- Development uses `deploy/development/observability/` only for local validation of the observability assets themselves.
