---
applyTo: "**/*.sql"
---

# SQL Instructions

Follow `.github/CONTRIBUTING.md` for SQL naming standards (MSSQL section).

For table creation and migrations, use `.github/skills/mssql-table-scaffolder/SKILL.md`.

The skill contains complete naming conventions, constraint patterns, index design, and migration workflows.

## SQL Script Rules (all .sql files)

1. **Table aliases** - Use table aliases consistently for table references in SQL statements. For MSSQL `UPDATE` and `DELETE`, the target table must be referenced through the `FROM` clause with an alias, and all `WHERE` clause columns must be prefixed with that alias.
2. **Transaction error handling** - When a script performs transactional data changes, use `SET XACT_ABORT ON`, wrap the transaction in `TRY...CATCH`, roll back when `@@TRANCOUNT > 0`, and rethrow with `THROW`.

## Embedded SQL Resources Pattern

When SQL is used from C# code, it must be stored as embedded `.sql` resource files, not as inline strings. The canonical folder layout and loader (`Resources/SQL/*.sql` + `Constants.cs` + `ResourceLoader.cs`) is defined in `.github/skills/dotnet-service-generator/references/standard-service.md` — follow it exactly.

### SQL Script Guidelines

1. **Header comments** - Document purpose, parameters, and security notes
2. **Parameter naming** - Use `@p0`, `@p1`, etc. for positional parameters (matches `sp_executesql` convention)
3. **Input validation** - Validate required parameters with `THROW`
4. **Schema validation** - Check table/schema existence before operations
5. **Use QUOTENAME()** - For dynamic object names to prevent injection
6. **DEBUG mode** - Always include a debug parameter and commented test block

### Transaction Error Handling Pattern

Use this pattern for transactional SQL scripts:

```sql
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    --...
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
```

### DEBUG Mode Pattern

Every embedded SQL script **must** include a debug mode that allows developers to test the script in SSMS without executing:

```sql
--! Feature Name - Operation Description
--! Parameters:
--!   @p0 (NVARCHAR) - Schema name
--!   @p1 (NVARCHAR) - Table name
--!   @pN (BIT)      - Debug mode (1 = print SQL without executing)

SET NOCOUNT ON;

/*
-- DEBUG: Uncomment this block to test the script in SSMS
DECLARE @p0 NVARCHAR(128) = N'dbo';
DECLARE @p1 NVARCHAR(128) = N'TestTable';
DECLARE @pN BIT = 1;  -- Set to 1 to see the generated SQL without executing
*/

DECLARE @SchemaName NVARCHAR(128) = @p0;
DECLARE @TableName NVARCHAR(128) = @p1;
DECLARE @Debug BIT = COALESCE(@pN, 0);

-- ... validation logic ...

DECLARE @Sql NVARCHAR(MAX) = N'...';
DECLARE @Id BIGINT = 123;

IF @Debug = 1
BEGIN
    PRINT '-- DEBUG: Generated SQL';
    RAISERROR (N'==> [DEBUG] @Sql: %s, @Id: %I64d', 0, 1, @Sql, @Id) WITH NOWAIT;
END
ELSE
BEGIN
    EXEC sp_executesql @Sql;
END
```

**Benefits:**
- Developers can test SQL logic directly in SSMS
- See exactly what SQL will be generated before execution
- Debug without modifying production code
- Validate parameter combinations safely

### Reference Implementation

The `MyOrganization.EntityFrameworkCore.SqlServer` workspace library (BatchLock feature) contains canonical examples — see the library table in `.github/skills/INDEX.md`.
