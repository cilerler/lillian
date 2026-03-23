---
description: Create Grafana dashboard for a service
---

# Dashboard Generator

Load and follow `.agent/skills/observability/SKILL.md` and its template at `.agent/skills/observability/templates/grafana-dashboard.md`.

## Requirements

1. **Output location**: Generate all dashboard JSON files under `tools/grafana/`
2. **Environment separation**: Every dashboard must include an `env` template variable with values: `integration`, `testing`, `staging`, `production`
3. **Query filtering**: Every PromQL query must include `env="$env"` and `service_name="$service"` selectors
4. **Datasource variable**: Every dashboard must use a `$datasource` template variable
5. **Placeholder**: Use `$(SERVICE_NAME)` in dashboard uid and title for deployment substitution

The template contains complete Grafana JSON for Service Health, API Performance, and Resource Usage dashboards. Use these as the starting point and customize panels based on the Architect's observability requirements.
