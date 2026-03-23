
# C# Instructions

Follow `.github/CONTRIBUTING.md` for all C# standards including:
- Async patterns and CancellationToken requirements
- Logging and configuration patterns
- Error handling and exceptions
- Concurrency and performance

For observability patterns, see `.agent/skills/observability/SKILL.md`.

## SQL in C# Code

**Do not generate dynamic SQL strings in C# code.** Instead, use embedded SQL resources:

1. Store SQL scripts as `.sql` files in a `Resources` folder
2. Embed them via csproj: `<EmbeddedResource Include="Services\**\Resources\*.sql" />`
3. Load via `SqlQuery` class using `AssemblyResourceReader.GetEmbeddedResourceContent()`
4. Use parameterized execution with `sp_executesql` or `SqlParameter`
5. Include a `bool debug = false` parameter in `SqlParameterBuilder` methods

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

See `EntityFrameworkCore.SqlServer/BatchLock/` for the canonical pattern:
- `Resources/SelectForUpdate.sql` - Embedded SQL script with debug mode
- `SqlQuery.cs` - Lazy-loaded resource accessor
- `Constants.cs` - Resource file name constants

### Benefits

- SQL syntax highlighting and validation in editors
- Proper code review of SQL changes (not hidden in C# strings)
- Separation of concerns (SQL logic vs C# orchestration)
- Debug mode for testing without execution
- Consistent pattern across the codebase
