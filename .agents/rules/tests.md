---
trigger: glob
globs: **/*Tests*/**
---

# Test Instructions

This file is the canonical authority for test implementation conventions.

Test-project placement/naming and HTTP-file placement/naming come from
[`Canonical test project and HTTP file naming`](../skills/solution-structure/SKILL.md#canonical-test-project-and-http-file-naming).

## Framework and isolation

- Use **MSTest** only; do not introduce xUnit or NUnit.
- Keep tests deterministic and isolated. Do not depend on execution order or shared mutable state.
- Test application behavior, not framework behavior.

## Test method naming

Use `{Method}_{Scenario}_{Expected}` for test method names.

## Unit tests

- Use fakes or mocks for dependencies.
- Focus on domain logic, edge cases, and failure paths.

## Integration tests

- Use **Testcontainers** when behavior depends on an external database, queue, cache, broker, or other provider.
- An EF Core test may use an isolated in-memory database only when provider-specific behavior is explicitly out
  of scope. Use the real provider through Testcontainers when SQL translation, constraints, transactions,
  concurrency, or provider behavior matters.
- When a test builds an application service provider or host, reproduce the production registration and
  configuration closure for every service under test. Registering an interface is insufficient when its
  implementation also requires options, cache, telemetry, or another prerequisite. Resolve every service under
  test during fixture startup so missing composition fails before test execution.

## Options validation tests

- Test property-level data annotations independently from cross-property or `IValidatableObject` invariants.
- Keep every property-level value valid in the cross-property case so object-level validation is guaranteed to
  run.

## Additional test types

- Add API contract tests when an API contract is in scope.
- Add property-based tests for parsers when they materially improve input-space coverage.
- Add a basic load smoke test for a critical path when performance or stability risk warrants it.
