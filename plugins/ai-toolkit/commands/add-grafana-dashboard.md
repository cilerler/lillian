---
description: Create Grafana dashboard for a service
---

# Dashboard Generator

Load and follow `${CLAUDE_PLUGIN_ROOT}/skills/observability/SKILL.md` and its template at `${CLAUDE_PLUGIN_ROOT}/skills/observability/templates/grafana-dashboard.md`.

## Requirements

1. **Output location**: Dashboards live alongside the code they monitor:
   - Service-level: `{ServicePath}/Observability/Grafana/dashboard.json`
   - Component-level: `{ComponentPath}/Observability/Grafana/dashboard.json`
   - Module-level: `{ModulePath}/Observability/Grafana/dashboard.json`
   - App-wide: `src/Observability/Grafana/dashboard.json`
2. **Environment separation**: Every dashboard must include an `env` template variable with values: `integration`, `testing`, `staging`, `production`
3. **Query filtering**: Every PromQL query must include `env="$env"` and `service_name="$service"` selectors
4. **Datasource variable**: Every dashboard must use a `$datasource` template variable
5. **Placeholder**: Use `$(SERVICE_NAME)` in dashboard uid and title for deployment substitution

The template contains complete Grafana JSON for Service Health, API Performance, and Resource Usage dashboards. Use these as the starting point and customize panels based on the Architect's observability requirements.
