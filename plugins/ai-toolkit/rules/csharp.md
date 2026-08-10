---
trigger: glob
globs: **/*.cs
---

# C# Instructions

Follow `.github/CONTRIBUTING.md` for all C# standards including:
- Async patterns and CancellationToken requirements
- Logging and configuration patterns
- Error handling and exceptions
- Concurrency and performance

For observability patterns, see `.github/skills/observability/SKILL.md`.

## SQL in C# Code

**Do not generate dynamic SQL strings in C# code.** Use embedded SQL resources instead.

The canonical layout and loader pattern (`Resources/SQL/*.sql`, `Constants.cs`, `ResourceLoader.cs`, the `.csproj` `<EmbeddedResource>` entry) is defined in `.github/skills/dotnet-service-generator/references/standard-service.md` — follow it exactly. On the C# side additionally:

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
