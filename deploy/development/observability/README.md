# Development Observability Stack

This is a minimal local single-machine observability path for developers.

It is intentionally isolated from the production and QA VM topology. It exists only for local validation of Prometheus, Grafana provisioning, dashboards, and rule files.

Local stack:

- Prometheus on `localhost:9090`
- Grafana on `localhost:3001`, configured for `/grafana/`
- local retention defaults to 7 days with WAL compression enabled
- Alertmanager is not started by default in development; local alert validation uses the shared rule files and config checks instead

The local compose file does not require the full Signhex runtime stack. It validates the observability assets themselves.
