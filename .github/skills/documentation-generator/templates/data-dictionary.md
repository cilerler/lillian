# Data Dictionary Catalog

## Overview

This document defines the schema, fields, data types, and data governance elements for [Database/System Name].

## Tables

### [Schema].[TableName]

| Field Name | Data Type | Length/Precision | Nullable | PK | FK | FK Reference | Default Value | Description | Sample Value | PII/Security | Notes |
|------------|-----------|------------------|----------|----|----|--------------|---------------|-------------|--------------|--------------|-------|
| [FieldName] | [Type] | [Length] | [Yes/No] | [Yes/No] | [Yes/No] | [Reference] | [Default] | [Description] | [Sample] | [Classification] | [Notes] |

## Example Entry

| Field Name | Data Type | Length/Precision | Nullable | PK | FK | FK Reference | Default Value | Description | Sample Value | PII/Security | Notes |
|------------|-----------|------------------|----------|----|----|--------------|---------------|-------------|--------------|--------------|-------|
| UserId | BIGINT | | No | Yes | No | | IDENTITY(1,1) | Unique identifier for the user | 1001 | None | System-generated |
| Email | NVARCHAR | 320 | No | | No | | | User's email address | user@example.com | PII-Confidential | Unique index |
| PasswordHash | NVARCHAR | 256 | No | | No | | | Hashed password | 0x2A... | Sensitive | Never store plain text |
| FirstName | NVARCHAR | 100 | Yes | | No | | | User's first name | John | PII-Confidential | |
| IsActive | BIT | | No | | No | | 1 | Account active flag | 1 | None | 1=Active, 0=Inactive |
| CreatedAt | DATETIME2 | 7 | No | | No | | SYSUTCDATETIME() | Record creation timestamp | 2025-01-15 14:30:00 | None | UTC |

## Column Definitions

### Data Types

| Type | Usage |
|------|-------|
| BIGINT | Primary keys, foreign keys, large integers |
| INT | Counts, quantities |
| NVARCHAR(n) | Unicode text with max length |
| VARCHAR(n) | ASCII text with max length |
| DATETIME2(7) | Timestamps (UTC) |
| BIT | Boolean flags |
| DECIMAL(p,s) | Money, precise decimals |
| UNIQUEIDENTIFIER | GUIDs, external references |

### PII/Security Classifications

| Classification | Description | Handling |
|---------------|-------------|----------|
| None | Non-sensitive data | Standard access |
| PII-Confidential | Personally identifiable information | Restricted access, encryption at rest |
| Sensitive | Credentials, secrets | Highly restricted, never logged |
| Financial | Payment, banking data | PCI compliance required |

## Foreign Key Relationships

```
[ParentTable] 1──────* [ChildTable]
     │
     └── [ParentTable].[PKColumn] → [ChildTable].[FKColumn]
```

## Indexes

| Table | Index Name | Columns | Type | Notes |
|-------|------------|---------|------|-------|
| [Table] | [IndexName] | [Columns] | [Clustered/Non-clustered] | [Purpose] |

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | [Date] | [Author] | Initial version |
