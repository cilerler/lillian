---
paths:
  - "**/*.cs"
---

# C# Instructions

This file is the canonical authority for C# implementation conventions.

## Concurrency and async

- Assume multithreaded execution.
- Use async I/O end-to-end and do not block asynchronous paths.
- Require `CancellationToken` on every public asynchronous API and propagate requested cancellation.

## Exceptions and API errors

- Define domain, transient, and fatal exception categories.
- Never swallow exceptions or use a catch-all without rethrowing.
- Map HTTP API errors to `ProblemDetails`.

## Performance, nullability, and immutable data

- Profile before optimizing, remove synchronous I/O, and reduce measured allocations.
- Avoid LINQ in hot paths unless measurement supports it.
- Enable nullable reference types.
- Prefer immutable records for DTOs and value objects.

## Persistence and caching

- Use EF Core with an explicit tracking strategy.
- Use `IDistributedCache` for caches shared across process instances.

## Configuration and dependency injection

- Application-owned registration and mapping extension APIs (`Add*` and `Map*`) do not accept
  `IConfiguration` or `IConfigurationSection`.
- Bind runtime options with `BindConfiguration`.
- When feature selection shapes the DI graph before the provider exists, bind one strongly typed composition
  snapshot at the deployable runner's composition root and pass that snapshot through registration and mapping.
- A deployable runner's composition root may pass configuration to a framework or third-party composition API
  whose contract requires it, but must not relay raw configuration through an application-owned cascade.
- Never build a temporary service provider.

## APIs, time, money, and serialization

- Document HTTP APIs with OpenAPI and version their routes.
- Use idempotency keys for applicable POST operations.
- Use `DateTimeOffset` at application boundaries and UTC for storage.
- Use `decimal` for money and culture-invariant parsing.
- Use System.Text.Json source generation, stable serialized field names, and backward-compatible DTO changes.

For observability implementation, see
[`OpenTelemetry Patterns`](../skills/observability/SKILL.md#opentelemetry-patterns).

## SQL in C# Code

**Do not generate dynamic SQL strings in C# code.** Use embedded SQL resources instead.

Embedded SQL placement and filenames come from
[`Canonical embedded SQL structure`](../skills/solution-structure/SKILL.md#canonical-embedded-sql-structure).
Follow
[`Resources/SQL/`](../skills/dotnet-service-generator/references/standard-service.md#resourcessql)
for the C# loader and project-file embedding implementation. On the C# side additionally:

1. Use parameterized execution with `sp_executesql` or `SqlParameter`
2. Include a `bool debug = false` parameter in `SqlParameterBuilder` methods (the SQL-side debug pattern is defined in the SQL instructions)

### SqlParameterBuilder Pattern

Parameter builders should include an optional debug flag that passes through to the SQL script:

```csharp
public static SqlParameter[] BuildParameters(
    string schemaName,
    string tableName,
    bool debug = false)  // Enables SQL debug mode
{
    return
    [
        new SqlParameter("@p0", SqlDbType.NVarChar, 128) { Value = schemaName },
        new SqlParameter("@p1", SqlDbType.NVarChar, 128) { Value = tableName },
        new SqlParameter("@p2", SqlDbType.Bit) { Value = debug }
    ];
}
```

This allows unit tests or debugging sessions to see generated SQL without execution.

### Reference Implementation

[Ruya.EntityFrameworkCore.SqlServer's BatchLock implementation](https://github.com/cilerler/ruya/tree/main/src/Ruya.EntityFrameworkCore.SqlServer/BatchLock) is the reference end-to-end example — embedded SQL, debug mode, lazy resource loading, and constants.

### Benefits

- SQL syntax highlighting and validation in editors
- Proper code review of SQL changes (not hidden in C# strings)
- Separation of concerns (SQL logic vs C# orchestration)
- Debug mode for testing without execution
- Consistent pattern across the codebase
