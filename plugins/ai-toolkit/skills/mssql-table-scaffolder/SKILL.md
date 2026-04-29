---
name: mssql-table-scaffolder
type: guidance
applies_to:
  - Developer
mandatory: conditional
triggers:
  - create table
  - generate table
  - scaffold table
  - standardize table
  - migrate table
references:
  - templates/create-new-table.sql
summary: Scaffolds production-ready MSSQL tables or generates migration scripts following enterprise conventions.
---

# Table Scaffolder

> **File placement when embedding SQL in a .NET service:** [`solution-structure`](../solution-structure/SKILL.md) § *.NET Solution* — embedded SQL files (`{Name}.sql`, `Constants.cs`, `ResourceLoader.cs`) live under `/src/.../{Service}/Resources/SQL/`. This skill produces the SQL itself; that skill defines where it goes in the repo.

## Purpose
Scaffolds production-ready Microsoft SQL Server `CREATE TABLE` scripts or generates migration scripts to standardize existing tables.

## When to Use
Use this when the user asks to:
- Create a new SQL Server table
- Generate a table script with specific features (temporal, soft delete, locking, etc.)
- Scaffold database tables following enterprise patterns
- Standardize, refactor, or analyze an existing (legacy/ugly) table
- Migrate a table to match enterprise conventions

## Role
You are a Senior Database Architect for Microsoft SQL Server.

## Operating Modes

### Mode 1: CREATE (New Table)
**Triggers:** "Create table", "Generate table", "Scaffold table"
**Output:** Complete `CREATE TABLE` script with all requested features

### Mode 2: ANALYZE/MIGRATE (Existing Table)
**Triggers:** "Standardize this table", "Analyze this table", "Refactor this", "Fix this table", "Migrate this"
**Output:** Migration script with ordered commands

#### Migration Script Structure
Generate commands in this execution order:

1. **Disable constraints/triggers** (if needed for safe migration)
2. **sp_rename** — Rename table/columns/constraints to match conventions
3. **ALTER TABLE ADD** — Missing standard columns (RowGuid, audit fields, etc.)
4. **ALTER TABLE ALTER COLUMN** — Fix data types
5. **ALTER TABLE DROP CONSTRAINT** — Remove non-conforming constraints
6. **ALTER TABLE ADD CONSTRAINT** — Add properly named constraints (PK, FK, DF, CHK)
7. **DROP INDEX / CREATE INDEX** — Fix index naming and add missing indexes
8. **CREATE TRIGGER** — Add triggers for requested features (soft delete, audit)
9. **Extended Properties** — Add/update column descriptions
10. **Re-enable constraints/triggers**

#### Migration Output Format
```sql
-- ============================================
-- MIGRATION SCRIPT: [TableName]
-- Generated: [Date]
-- Mode: Analyze/Standardize
-- ============================================

PRINT 'Starting migration for [Schema].[TableName]...';
GO

-- [1] RENAMES
EXEC sp_rename '[Schema].[OldTableName]', 'NewTableName';
EXEC sp_rename '[Schema].[TableName].[oldColumn]', 'NewColumn', 'COLUMN';
EXEC sp_rename 'Schema.OldConstraintName', 'PK_TableName_Id', 'OBJECT';
GO

-- [2] ADD MISSING COLUMNS
ALTER TABLE [Schema].[TableName] ADD 
    RowGuid UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL
        CONSTRAINT DF_TableName_RowGuid DEFAULT (NEWID()),
    -- ... other columns
GO

-- [3] MODIFY EXISTING COLUMNS
-- ... 

-- [4] CONSTRAINTS
-- ...

-- [5] INDEXES
-- ...

-- [6] TRIGGERS
-- ...

-- [7] EXTENDED PROPERTIES
-- ...

PRINT 'Migration complete.';
GO
```

---

## Process

### Step 0: Determine Mode
- If user provides existing CREATE TABLE → **ANALYZE/MIGRATE** mode
- If user requests new table → **CREATE** mode

### Step 1: Parse User Request
Extract from the user's request:
- **Schema name** (default: `dbo`)
- **Table name** (singular, PascalCase)
- **Columns** with types (or infer from naming conventions)
- **Features requested** (see Feature Matrix below)
- **Relationships** (parent tables, self-referencing)

### Step 2: Transform Template

#### Naming Replacements
| Template Term | Replace With |
|---------------|--------------|
| `MySchema` | Requested schema (default: `dbo`) |
| `MyTable` | Requested table name |
| `MyTableId` | `{TableName}Id` |
| `MyParentTable` | Parent table name (if FK exists) |
| `MyParentTableId` | `{ParentTableName}Id` |

**Important:** Rename ALL constraints, indexes, triggers, and views to match the new table name. Never leave `MyTable` in any object name.

#### Feature Matrix (Subtraction Rule)
The template includes ALL features. **Remove** code blocks for features NOT requested:

| Feature | If NOT Requested, Remove |
|---------|--------------------------|
| **Locking** | `LockState`, `LockTime`, `LockedBy`, `IsLocked` columns + extended properties |
| **Soft Delete** | `SoftDelete` column, `INSTEAD OF DELETE` trigger, View definition |
| **Delete Logging** | `DeleteLog` schema, `DeleteLog.Record` table, `AFTER DELETE` trigger |
| **Hierarchy** | `ParentId`, `NestedParentId`, `HierarchyId`, `HierarchyLevel`, `HierarchyPath` + indexes |
| **Temporal** | `ValidFrom`, `ValidTo`, `PERIOD FOR SYSTEM_TIME`, `SYSTEM_VERSIONING` clause |
| **Full-Text** | `CREATE FULLTEXT CATALOG`, `CREATE FULLTEXT INDEX` |
| **Lookup** | `LookupValueCode` column, `LookupValue`/`LookupGroup`/`LookupGroupMapping` tables |
| **Processing Order** | `ProcessingOrder` column |

### Step 3: Inject Custom Columns
Add user-requested columns using these type inference rules:

| Pattern | Inferred Type |
|---------|---------------|
| `*Id` | `BIGINT` |
| `Is*`, `Has*` | `BIT NOT NULL DEFAULT(0)` |
| `*Date`, `*At` | `DATETIME2(7)` |
| `Name`, `Code` | `VARCHAR(100)` or `NVARCHAR(100)` |
| `Description`, `Note`, `*Text` | `VARCHAR(MAX)` or `NVARCHAR(MAX)` |
| `Price`, `Amount`, `*Cost` | `DECIMAL(19, 4)` |
| `Count`, `Quantity` | `INT` |
| `Percentage`, `Rate` | `DECIMAL(5, 2)` |
| `Email` | `VARCHAR(320)` |
| `Url` | `VARCHAR(2048)` |

## Example Invocations

### CREATE Mode Examples

#### Minimal Table
```
Create a Customer table with Name and Email
```
Output: Basic table with standard audit columns only.

#### Full-Featured Table
```
Create an Order table in Sales schema with:
- CustomerId (FK to Customer)
- OrderDate, TotalAmount, Notes
- Features: Temporal, Soft Delete, Locking
```

#### Hierarchical Table
```
Create a Category table with:
- Name, Description
- Self-referencing hierarchy
- Features: Hierarchy, Soft Delete
```

### ANALYZE/MIGRATE Mode Examples

#### Standardize Legacy Table
```
Standardize this table:

CREATE TABLE tblCust (
    id int identity primary key,
    fname varchar(50),
    lname varchar(50),
    created datetime
)
```
Output: Migration script with sp_rename, ADD columns, fix constraints.

#### Add Features to Existing Table
```
Analyze this table and add Soft Delete and Temporal features:

CREATE TABLE [dbo].[Product] (...)
```
Output: ALTER statements to add required columns, triggers, and versioning.

#### Full Audit
```
What's wrong with this table? Fix it.

CREATE TABLE orders (...)
```
Output: Analysis of issues + complete migration script.

## Output Format
Always output a single, complete T-SQL script in a code block. Include:
1. Table creation with all columns
2. Required indexes
3. Triggers (based on features)
4. Extended properties
5. Any supporting objects (views, lookup tables)
