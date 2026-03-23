---
description: "Perform comprehensive code review for quality, security, and best practices"
---

# Comprehensive Code Review

Perform a deep, thorough code review examining all aspects of code quality.

## Scope

Identify the code to review (files, PR, or specified scope).

## Review Dimensions

### 1. Code Quality
- Readability and clarity
- Naming conventions (per `.github/CONTRIBUTING.md`)
- Code organization and structure
- DRY principle adherence
- SOLID principles adherence
- Appropriate abstractions

### 2. Security
- Input validation and sanitization
- SQL injection vulnerabilities
- XSS vulnerabilities
- Authentication/authorization checks
- Sensitive data exposure
- Secrets in code

### 3. Error Handling
- Exception handling completeness
- Error messages (informative but not leaking internals)
- Graceful degradation
- Retry logic where appropriate
- Transaction rollback handling

### 4. Performance
- N+1 query problems
- Unnecessary allocations
- Missing indexes (for new queries)
- Caching opportunities
- Async/await correctness
- Resource disposal

### 5. Observability
- Logging at appropriate levels
- Structured logging with context
- Metrics instrumentation
- Trace propagation
- Health check coverage

### 6. Architecture
- Clean architecture boundaries
- Domain logic in correct layer
- Dependency direction
- Interface segregation
- Coupling and cohesion

### 7. Testing
- Unit test coverage for new code
- Edge cases covered
- Test determinism
- Mock/fake appropriateness

### 8. Standards Compliance
- `.github/CONTRIBUTING.md` adherence
- Applicable skills from `.agent/skills/INDEX.md` applied correctly

## Output Format

### Summary

[1-2 sentence overall assessment]

### Verdict: PASS or FAIL

### Findings by Category

**Security** (Critical)
- [list or "None"]

**Blocker** (Prevents merge)
- [list or "None"]

**Major** (Must fix)
- [list or "None"]

**Minor** (Should fix)
- [list or "None"]

**Nitpick** (Optional)
- [list or "None"]

### Fix Checklist (if FAIL)

1. [Specific fix with file:line reference]
2. [Specific fix with file:line reference]

### Recommendations (if PASS)

| Area | Recommendation | Priority |
|------|----------------|----------|
| [area] | [recommendation] | High/Medium/Low |
