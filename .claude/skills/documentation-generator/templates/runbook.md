# Runbook: [Title]

## Purpose

[Brief description of what this runbook addresses. What problem does it solve?]

## Prerequisites

- [Required access or permissions]
- [Required tools or CLI access]
- [Required knowledge or documentation to review first]

## Steps

> **Note:** Use PowerShell syntax in all shell commands. Do not use Unix-style commands like `grep`.

### 1. [First Step Title]

[Description of what this step accomplishes]

```pwsh
[command to run]
```

**Expected output:** [What you should see if successful]

### 2. [Second Step Title]

[Description]

```pwsh
[command to run]
```

**Expected output:** [What you should see]

### 3. [Third Step Title]

[Description]

```pwsh
[command to run]
```

**Expected output:** [What you should see]

### 4. Verify Resolution

[How to confirm the issue is resolved]

```pwsh
[verification command]
```

**Expected output:** [What success looks like]

### 5. Check Monitoring

- Visit: `[Grafana/monitoring URL]`
- Navigate to: `[Dashboard path]`
- Verify: [What to look for]

## Rollback Plan

If the resolution does not work or makes things worse:

1. [Rollback step 1]
   ```pwsh
   [rollback command]
   ```

2. [Rollback step 2]

3. Escalate to on-call engineer

## Escalation

| Condition | Contact | Method |
|-----------|---------|--------|
| If unresolved after 15 minutes | [Team/Person] | [Slack/PagerDuty] |
| If data loss suspected | [Team/Person] | [Method] |
| If customer-facing impact | [Team/Person] | [Method] |

## Contact

- **Primary:** [Name] (`@handle` on Slack)
- **Backup:** [Team] (`#channel`)

## Related Documentation

- [Link to related runbook]
- [Link to architecture documentation]
- [Link to service README]
