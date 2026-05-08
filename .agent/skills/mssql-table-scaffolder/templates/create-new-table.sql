/*
1. Replace the schema name MySchema with your desired schema (e.g., dbo) before use.
2. Replace the column name MyParentTableId with your desired column name (e.g., Id) before use.
3. Ensure the table name MyParentTable matches your intended table name before use.
4. Replace the variable name MyTableId with your desired variable name (e.g., Id) before use.
5. Ensure the table name MyTable matches your intended table name before use.
*/

CREATE TABLE [MySchema].[MyTable]
(
    MyTableId BIGINT IDENTITY(1, 1) NOT FOR REPLICATION NOT NULL
        CONSTRAINT PK_MyTable_MyTableId
            PRIMARY KEY CLUSTERED (MyTableId ASC),
    RowGuid UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL
        CONSTRAINT DF_MyTable_RowGuid
            DEFAULT (NEWID()),
    [RowVersion] ROWVERSION,
    CreatedAt DATETIME2(7) NOT NULL
        CONSTRAINT DF_MyTable_CreatedAt
            DEFAULT (SYSUTCDATETIME()),
    ModifiedAt DATETIME2(7) NOT NULL
        CONSTRAINT DF_MyTable_ModifiedAt
            DEFAULT (SYSUTCDATETIME()),
    ModifiedBy VARCHAR(261) NOT NULL
        CONSTRAINT DF_MyTable_ModifiedBy
            DEFAULT (SUSER_SNAME()),
    SoftDelete BIT NOT NULL     -- WARNING: Remove if using temporal tables or cascading FK constraints (INSTEAD OF trigger limitation).
        CONSTRAINT DF_MyTable_SoftDelete
            DEFAULT (0),
    [Enabled] BIT NOT NULL
        CONSTRAINT DF_MyTable_Enabled
            DEFAULT (0),
    ProcessingOrder TINYINT NOT NULL
        CONSTRAINT DF_MyTable_ProcessingOrder
            DEFAULT (0),

    LockState TINYINT NULL,
    LockTime DATETIME2(7) NULL,
    LockedBy VARCHAR(261) NULL,
    IsLocked AS CAST(
                 CASE
                     WHEN  LockState IS NOT NULL
                           AND LockState > 0
                           AND DATEDIFF(MINUTE, LockTime, SYSUTCDATETIME()) <= 15
                     THEN 1
                     ELSE 0
                 END
                 AS BIT),           -- WARNING: Keyword 'PERSISTED' cannot be specified after 'END' when the time-based condition is present, as the expression is non-deterministic.

    LookupValueCode TINYINT NULL
        CONSTRAINT FK_MyTable_LookupValue_LookupValueCode
            FOREIGN KEY (LookupValueCode)
            REFERENCES [MySchema].[LookupValue] (Code)
            ON DELETE SET NULL  -- WARNING: Remove if using temporal tables
            ON UPDATE CASCADE,  -- WARNING: Remove if using temporal tables

    ParentId BIGINT NULL
        CONSTRAINT FK_MyTable_MyParentTable_ParentId
            FOREIGN KEY (ParentId)
            REFERENCES [MySchema].[MyParentTable] (MyParentTableId)
            ON DELETE CASCADE   -- WARNING: Remove if using temporal tables
            ON UPDATE CASCADE,  -- WARNING: Remove if using temporal tables

    NestedParentId BIGINT NULL
        CONSTRAINT FK_MyTable_MyTable_NestedParentId
            REFERENCES [MySchema].[MyTable] (MyTableId)
            ON DELETE SET NULL   -- WARNING: Remove if using temporal tables
            ON UPDATE NO ACTION, -- WARNING: Remove if using temporal tables

    [HierarchyId] HIERARCHYID NOT NULL
        CONSTRAINT DF_MyTable_HierarchyId
            DEFAULT (HIERARCHYID::GetRoot())
        CONSTRAINT CHK_MyTable_HierarchyId_NotEmpty
            CHECK ([HierarchyId].ToString() <> ''),
    HierarchyLevel AS [HierarchyId].GetLevel() PERSISTED,
    HierarchyPath AS [HierarchyId].ToString() PERSISTED,

    -- System-versioned temporal tables to automatically track historical changes and deletions.
    ValidFrom DATETIME2(7) GENERATED ALWAYS AS ROW START HIDDEN,
    ValidTo DATETIME2(7) GENERATED ALWAYS AS ROW END HIDDEN,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),

    -- SHA-256 hash of designated dedup columns; auto-populated by `MyTable_DedupeHash` trigger for duplicate detection.
    DedupeHash VARBINARY(32) NOT NULL
        CONSTRAINT DF_MyTable_DedupeHash
            DEFAULT (0x),

    [Description] VARCHAR(50) NOT NULL
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [MySchema].[MyTableHistory], DATA_CONSISTENCY_CHECK = ON));
GO

CREATE UNIQUE NONCLUSTERED INDEX UIX_MyTable_RowGuid ON [MySchema].[MyTable](RowGuid)
GO

-- Breadth-first: by level, then ID
CREATE NONCLUSTERED INDEX IX_MyTable_HierarchyLevel_BreadthFirst
    ON [MySchema].[MyTable]([HierarchyLevel], MyTableId);
GO

-- Depth-first: hierarchy traversal by HierarchyId path
CREATE UNIQUE NONCLUSTERED INDEX UIX_MyTable_HierarchyId_DepthFirst
    ON [MySchema].[MyTable]([HierarchyId]);
GO

-- Foreign key index (Self-referencing parent entity)
CREATE NONCLUSTERED INDEX IX_MyTable_NestedParentId
    ON [MySchema].[MyTable](NestedParentId);
GO

-- Foreign key index (External table reference)
CREATE NONCLUSTERED INDEX IX_MyTable_ParentId
    ON [MySchema].[MyTable](ParentId);
GO

-- Column 'IsLocked' is a computed column with non-deterministic expression and cannot be used in an index or statistics or as a partition key because it is non-deterministic.
CREATE NONCLUSTERED INDEX IX_MyTable_SoftDelete_ModifiedAt_ProcessingOrder_LockState
    ON [MySchema].[MyTable]([SoftDelete] ASC, [Enabled] ASC, [ModifiedAt] DESC, [ProcessingOrder] ASC, [LockState] ASC)
    INCLUDE (MyTableId, ParentId, LockedBy);
GO

CREATE NONCLUSTERED INDEX IX_MyTable_LookupValueCode
    ON [MySchema].[MyTable](LookupValueCode);
GO

-- Non-unique by default; promote to UNIQUE to enforce duplicate prevention at the database level.
CREATE NONCLUSTERED INDEX IX_MyTable_DedupeHash
    ON [MySchema].[MyTable](DedupeHash);
GO

CREATE TRIGGER [MySchema].[MyTable_StampModifiedAt] ON [MySchema].[MyTable]
	AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF ((SELECT TRIGGER_NESTLEVEL()) > 1) RETURN;

    IF NOT UPDATE(ModifiedAt)
    BEGIN
        UPDATE  entity
        SET     entity.ModifiedAt = SYSUTCDATETIME()
        FROM    [MySchema].[MyTable] AS entity
            JOIN INSERTED AS i
                ON entity.MyTableId = i.MyTableId;
    END
    ELSE
    BEGIN
        UPDATE  entity
        SET     entity.ModifiedAt = CASE
                                    WHEN entity.ModifiedAt > i.ModifiedAt
                                    THEN entity.ModifiedAt
                                    ELSE i.ModifiedAt
                                END
        FROM    [MySchema].[MyTable] AS entity
            JOIN INSERTED AS i
                ON entity.MyTableId = i.MyTableId;
    END
END
GO

-- Computes a SHA-256 hash from designated dedup columns to enable duplicate detection.
-- Replace DedupeColumn1, DedupeColumn2 (and add additional ISNULL terms in CONCAT_WS) with the actual columns that define a duplicate.
-- CHAR(31) (Unit Separator) is used as a delimiter to prevent collisions across column boundaries.
CREATE TRIGGER [MySchema].[MyTable_DedupeHash] ON [MySchema].[MyTable]
    AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF ((SELECT TRIGGER_NESTLEVEL()) > 1) RETURN;

    IF NOT (UPDATE(DedupeColumn1) OR UPDATE(DedupeColumn2))
        RETURN;

    UPDATE  entity
    SET     entity.DedupeHash = CAST(HASHBYTES('SHA2_256',
                CONCAT_WS(CHAR(31),
                    ISNULL(i.DedupeColumn1, ''),
                    ISNULL(i.DedupeColumn2, '')
                )
            ) AS VARBINARY(32))
    FROM    [MySchema].[MyTable] AS entity
        JOIN INSERTED AS i
            ON entity.MyTableId = i.MyTableId;
END
GO

-- Soft delete; marks records as deleted by updating a 'SoftDelete' flag instead of physically removing data.
-- Note: This prevents the row from ever being physically deleted by a standard DELETE statement.
-- Consequently, the 'MyTable_LogHardDelete' trigger below will NEVER fire unless this trigger is disabled or bypassed.

CREATE TRIGGER [MySchema].[MyTable_SoftDelete] ON [MySchema].[MyTable]
   INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE entity
	SET entity.SoftDelete = 1
	FROM [MySchema].[MyTable] AS entity
	INNER JOIN DELETED AS d
		ON entity.MyTableId = d.MyTableId;
END
GO

CREATE TABLE [DeleteLog].[Record]
(
    Id BIGINT IDENTITY(1, 1) NOT FOR REPLICATION NOT NULL
        CONSTRAINT PK_DeleteLog_Id
            PRIMARY KEY CLUSTERED (Id ASC),
    RowGuid UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL
        CONSTRAINT DF_DeleteLog_RowGuid
            DEFAULT (NEWID()),
    [RowVersion] ROWVERSION,
    DeletedAt DATETIME2(7) NOT NULL
        CONSTRAINT DF_DeleteLog_DeletedAt
            DEFAULT (SYSUTCDATETIME()),
    DeletedBy VARCHAR(261) NOT NULL
        CONSTRAINT DF_DeleteLog_ModifiedBy
            DEFAULT (SUSER_SNAME()),
    FullyQualifiedTableName VARCHAR(261) NOT NULL,
    EntityId BIGINT NOT NULL
)
GO

CREATE UNIQUE NONCLUSTERED INDEX UIX_Record_RowGuid ON [DeleteLog].[Record](RowGuid)
GO

CREATE NONCLUSTERED INDEX IX_Record_DeletedAt_FullyQualifiedTableName ON [DeleteLog].[Record] ([DeletedAt] ASC, [FullyQualifiedTableName] ASC) INCLUDE (EntityId);
GO

ALTER TABLE [DeleteLog].[Record] WITH CHECK ADD CONSTRAINT [CF_Record_FullyQualifiedTableName] CHECK ([FullyQualifiedTableName]='MySchema.MyTable')
GO

-- External delete logging; physically deletes records and logs deletions into an external audit/logging table.
CREATE TRIGGER [MySchema].[MyTable_LogHardDelete] ON [MySchema].[MyTable]
   AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON;

	INSERT [DeleteLog].[Record] (
	    FullyQualifiedTableName,
		EntityId,
        DeletedAt,
        DeletedBy
	)
	SELECT
        'MySchema.MyTable',
        d.MyTableId,
        SYSUTCDATETIME(),
        d.ModifiedBy
	FROM DELETED AS d
END
GO

CREATE VIEW [MySchema].[MyView]
WITH SCHEMABINDING
AS
SELECT
    entity.MyTableId
  , entity.RowGuid
  , entity.[RowVersion]
  , entity.CreatedAt
  , entity.ModifiedAt
  , entity.ModifiedBy
  , CONVERT(bit, 0) AS HardDelete
  , NULL AS DeleteLogId
  , NULL AS FullyQualifiedTableName
FROM
    [MySchema].[MyTable] AS entity
UNION ALL
SELECT
    dl.EntityId
  , dl.RowGuid
  , dl.[RowVersion]
  , NULL         AS CreatedAt
  , dl.DeletedAt AS ModifiedAt
  , dl.DeletedBy AS ModifiedBy
  , CONVERT(bit, 1) AS HardDelete
  , dl.Id AS DeleteLogId
  , dl.FullyQualifiedTableName
FROM
    [DeleteLog].[Record] AS dl
WHERE
    dl.FullyQualifiedTableName = 'MySchema.MyTable';
GO

CREATE UNIQUE CLUSTERED INDEX IX_MyView_MyTableId_HardDelete ON [MySchema].[MyView] (MyTableId, HardDelete);
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Auto-generated identity key uniquely identifying each record.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'MyTableId';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'ROWGUIDCOL uniquely identifying each row for replication purposes.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'RowGuid';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Automatically generated timestamp for row versioning; useful for concurrency checks.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'RowVersion';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'UTC timestamp when the record was created.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'CreatedAt';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'UTC timestamp indicating the last modification of the entity record.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'ModifiedAt';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Username of the user who last modified the entity record.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'ModifiedBy';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Indicates logical deletion; 1 if the entity is logically deleted, otherwise 0.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'SoftDelete';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Indicates whether the entity is currently enabled; 1 if enabled, otherwise 0.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'Enabled';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Determines the processing order of entities; lower values are processed first.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'ProcessingOrder';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Indicates the type or level of lock applied to the entity. `NULL` = never executed; `0` = executed and completed; `1-255` = custom-defined process stages.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'LockState';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'UTC timestamp indicating when the entity was locked; null if unlocked.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'LockTime';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = 'Hostname indicating the machine that currently holds the lock on the entity.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'LockedBy';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Computed column indicating lock presence; 1 if locked, otherwise 0.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'IsLocked';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Foreign key referencing the `LookupValue` table; nullable. Identifies a specific lookup value associated with the entity.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'LookupValueCode';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Foreign key linking to the parent entity in `MyParentTable` table; nullable.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'ParentId';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Self-referencing foreign key indicating the immediate parent.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'NestedParentId';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'HierarchyID representing the position of the entity within a hierarchical structure.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'HierarchyId';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Computed column representing the depth level within the hierarchy; root is level 0.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'HierarchyLevel';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Computed string representation of the hierarchy path, derived from HierarchyId.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'HierarchyPath';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'System-versioned temporal table column marking the start time of row validity period.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'ValidFrom';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'System-versioned temporal table column marking the end time of row validity period.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'ValidTo';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'SHA-256 hash of designated dedup columns; auto-populated by the AFTER INSERT/UPDATE trigger to enable duplicate detection.',
                                @level0type = N'SCHEMA', @level0name = N'MySchema',
                                @level1type = N'TABLE',  @level1name = N'MyTable',
                                @level2type = N'COLUMN', @level2name = N'DedupeHash';
GO


/*
-- TEMPORAL TABLE MANAGEMENT COMMANDS
-- ===================================
-- [1] Temporarily Disable Versioning (preserves period columns)
ALTER TABLE [MySchema].[MyTable] SET (SYSTEM_VERSIONING = OFF);
GO

-- [2] Permanently Remove Temporal Definitions (requires redefining to enable again)
ALTER TABLE [MySchema].[MyTable] DROP PERIOD FOR SYSTEM_TIME;
GO
*/

CREATE FULLTEXT CATALOG FTC_MyFullTextCatalog AS DEFAULT;
GO

CREATE FULLTEXT INDEX ON [MySchema].[MyTable] ([Description])
KEY INDEX PK_MyTable_MyTableId ON FTC_MyFullTextCatalog
WITH STOPLIST = SYSTEM;
GO

/*
ALTER FULLTEXT INDEX ON [MySchema].[MyTable] START FULL POPULATION;
ALTER FULLTEXT INDEX ON [MySchema].[MyTable] PAUSE POPULATION;
ALTER FULLTEXT INDEX ON [MySchema].[MyTable] RESUME POPULATION;
ALTER FULLTEXT INDEX ON [MySchema].[MyTable] REBUILD;
DROP FULLTEXT INDEX ON [MySchema].[MyTable]
*/

/*
-- FULL-TEXT CATALOG MANAGEMENT & STATUS CHECKS
-- =============================================
-- [1] Verify if Full-Text Search is installed on the server.
SELECT SERVERPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;

-- [2] Check catalog population completion status, current activity, and indexed item count.
SELECT FULLTEXTCATALOGPROPERTY('FTC_MyFullTextCatalog', 'PopulateCompletion') AS PopulateCompletion,
    CASE FULLTEXTCATALOGPROPERTY('FTC_MyFullTextCatalog', 'PopulateStatus')
        WHEN 0 THEN 'Idle (no population running)'
        WHEN 1 THEN 'Full population in progress'
        WHEN 2 THEN 'Paused'
        WHEN 3 THEN 'Throttled (paused due to resource limit)'
        WHEN 4 THEN 'Recovering'
        WHEN 5 THEN 'Shutdown'
        WHEN 6 THEN 'Incremental population in progress'
        WHEN 7 THEN 'Building index'
        WHEN 8 THEN 'Disk full (population stopped)'
        WHEN 9 THEN 'Change Tracking (auto-population running)'
        ELSE 'Unknown'
    END AS PopulationStatus,
FORMAT(FULLTEXTCATALOGPROPERTY('FTC_MyFullTextCatalog', 'ItemCount'),'N0') AS IndexedItemCount;

-- [3] Inspect ongoing full-text index populations, their types, statuses, and start times per table.
SELECT
    OBJECT_SCHEMA_NAME(p.table_id) AS SchemaName,
    OBJECT_NAME(p.table_id) AS TableName,
    CASE p.status
        WHEN 0 THEN 'Idle (no population running)'
        WHEN 1 THEN 'Full population in progress'
        WHEN 2 THEN 'Paused'
        WHEN 3 THEN 'Throttled (paused due to resource limit)'
        WHEN 4 THEN 'Recovering'
        WHEN 5 THEN 'Shutdown'
        WHEN 6 THEN 'Incremental population in progress'
        WHEN 7 THEN 'Building index'
        WHEN 8 THEN 'Disk full (population stopped)'
        WHEN 9 THEN 'Change Tracking (auto-population running)'
        ELSE 'Unknown'
    END AS PopulationStatus,
    CASE p.population_type
        WHEN 1 THEN 'Full'
        WHEN 2 THEN 'Incremental'
        WHEN 3 THEN 'Manual'
        WHEN 4 THEN 'Auto'
        ELSE 'Unknown'
    END AS PopulationType,
    p.start_time AS StartTime
FROM sys.dm_fts_index_population AS p;
*/

CREATE TABLE [MySchema].[LookupValue] (
    Code TINYINT NOT NULL
        CONSTRAINT PK_LookupValue_Code
        PRIMARY KEY CLUSTERED (Code ASC),
    Name VARCHAR(50) NOT NULL
        CONSTRAINT UQ_LookupValue_Name
        UNIQUE,
    Description VARCHAR(512) NULL
);

CREATE TABLE [MySchema].[LookupGroup] (
    Code TINYINT NOT NULL
        CONSTRAINT PK_LookupGroup_Code
        PRIMARY KEY CLUSTERED (Code ASC),
    Name VARCHAR(50) NOT NULL
        CONSTRAINT UQ_LookupGroup_Name
        UNIQUE,
    Description VARCHAR(512) NULL
);

CREATE TABLE [MySchema].[LookupGroupMapping] (
    Id SMALLINT IDENTITY(1, 1) NOT NULL
        CONSTRAINT PK_LookupGroupMapping_Id
        PRIMARY KEY CLUSTERED (Id ASC),
    LookupGroupCode TINYINT NOT NULL,
    LookupValueCode TINYINT NOT NULL,
    CONSTRAINT FK_LookupGroupMapping_LookupValue_LookupValueCode
        FOREIGN KEY(LookupValueCode)
        REFERENCES [MySchema].[LookupValue](Code)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT FK_LookupGroupMapping_LookupGroup_LookupGroupCode
        FOREIGN KEY(LookupGroupCode)
        REFERENCES [MySchema].[LookupGroup](Code)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE NONCLUSTERED INDEX IX_LookupGroupMapping_LookupGroupCode
    ON [MySchema].[LookupGroupMapping](LookupGroupCode);

CREATE NONCLUSTERED INDEX IX_LookupGroupMapping_LookupValueCode
    ON [MySchema].[LookupGroupMapping](LookupValueCode);
