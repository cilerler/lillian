# Data Dictionary

## Metadata

**Last Updated:** [YYYYMMDD]
**Owner:** [Name]

## Overview

This document defines the schema, fields, data types, and data governance elements for [Database/System Name].

## Tables

### [Schema].[TableName]

| Field Name | Data Type | Length/Precision | Nullable | PK | FK | FK Reference | Default Value | Description | Source System | Sample Value | PII/Security | Notes |
|------------|-----------|------------------|----------|----|----|--------------|---------------|-------------|---------------|--------------|--------------|-------|
| [FieldName] | [Type] | [Length] | [Yes/No] | [Yes/No] | [Yes/No] | [Reference] | [Default] | [Description] | [Source] | [Sample] | [Classification] | [Notes] |

> **Source System rule:** one row per (field, source). If the same field name is populated by two upstream systems — e.g., `Email` arrives from both `AuthService` and a CRM import — they get **two separate rows**, one per source, even within the same target table. This preserves lineage and prevents silent overwrites between sources.

## Example Entry

| Field Name | Data Type | Length/Precision | Nullable | PK | FK | FK Reference | Default Value | Description | Source System | Sample Value | PII/Security | Notes |
|------------|-----------|------------------|----------|----|----|--------------|---------------|-------------|---------------|--------------|--------------|-------|
| UserId | BIGINT | | No | Yes | No | | IDENTITY(1,1) | Unique identifier for the user | AuthService | 1001 | None | System-generated |
| Email | NVARCHAR | 320 | No | | No | | | User's email address | AuthService | user@example.com | PII-Confidential | Unique index |
| PasswordHash | NVARCHAR | 256 | No | | No | | | Hashed password | AuthService | 0x2A... | Sensitive | Never store plain text |
| FirstName | NVARCHAR | 100 | Yes | | No | | | User's first name | ProfileService | John | PII-Confidential | Sourced from profile API, not auth |
| IsActive | BIT | | No | | No | | 1 | Account active flag | AuthService | 1 | None | 1=Active, 0=Inactive |
| CreatedAt | DATETIME2 | 7 | No | | No | | SYSUTCDATETIME() | Record creation timestamp | AuthService | 2025-01-15 14:30:00 | None | UTC |

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
| 1.0 | [YYYYMMDD] | [Name] | Initial version |
