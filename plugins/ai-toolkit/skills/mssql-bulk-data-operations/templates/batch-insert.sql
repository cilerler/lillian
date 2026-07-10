/*
PURPOSE (INSERT SCRIPT):
This script identifies and tracks records that need to be processed from a source table.

HOW IT WORKS:
1. Creates a tracking table with IDs from the source table (dbo.MyTable)
2. Processes records in configurable batches (default 4500 records per batch)
3. Works through the source table in ID order
4. Provides detailed progress reporting during execution
5. Implements regular checkpoints to minimize transaction log growth

CONFIGURATION:
- @BatchSize: Number of records processed in each batch (default: 4500)
- @MaxBatchesToProcess: Limit on total batches to process (0 = unlimited)
- @BatchesPerCheckpoint: How often to checkpoint to minimize log growth

USAGE NOTES:
- This script should be run FIRST to populate the tracking table
- The tracking table (BulkProcessTracking.yyyyMMddHHmm_Tracker) will be used by the UPDATE script
- Replace "dbo.MyTable" with your actual source table name
*/

/*
-- Create the schema and tracking table
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'BulkProcessTracking')
BEGIN
    CREATE SCHEMA [BulkProcessTracking];
END
GO

-- Create the main tracking table (simplified version without IsProcessed)
CREATE TABLE [BulkProcessTracking].[yyyyMMddHHmm_Tracker]
(
    ID BIGINT PRIMARY KEY,               -- ID to be updated
    IsProcessed BIT NOT NULL DEFAULT 0   -- Flag to indicate whether the row has been processed (0 = Not Processed, 1 = Processed)
);

-- Create the index for performance on the IsProcessed column
CREATE NONCLUSTERED INDEX IDX_IsProcessed
ON [BulkProcessTracking].[yyyyMMddHHmm_Tracker](IsProcessed)
INCLUDE (ID);
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Detect if CHECKPOINT is beneficial (only in SIMPLE recovery model, not Azure SQL/Hyperscale)
DECLARE @UseCheckpoint BIT = 0;
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND recovery_model_desc = 'SIMPLE')
   AND SERVERPROPERTY('EngineEdition') NOT IN (5, 8) -- 5 = Azure SQL Database, 8 = Azure SQL Managed Instance
BEGIN
    SET @UseCheckpoint = 1;
    RAISERROR(N'CHECKPOINT enabled (SIMPLE recovery model detected)', 0, 1) WITH NOWAIT;
END
ELSE
BEGIN
    RAISERROR(N'CHECKPOINT disabled (FULL/BULK_LOGGED recovery or Azure SQL detected)', 0, 1) WITH NOWAIT;
END

-- Operation to perform batch inserts
DECLARE @MinID BIGINT = (SELECT ISNULL(MAX(Id) + 1, (SELECT MIN(Id) FROM dbo.MyTable)) FROM [BulkProcessTracking].[yyyyMMddHHmm_Tracker]);  -- Get the minimum Id to start processing from
DECLARE @MaxID BIGINT = (SELECT MAX(Id) FROM dbo.MyTable);  -- Get the maximum Id to determine the end of processing

DECLARE @MaxBatchesToProcess INT = 0;  -- Set the initial value to 0 to process all records in a single batch. If you specify any other number, it will process only that many batches.
DECLARE @BatchSize INT = 4500; --Use batch processing (e.g., < 5,000 rows per batch) to avoid table locks during large operations.
DECLARE @BatchesPerCheckpoint INT = 20; -- Checkpoint after every n batches to minimize the impact on the transaction log (only when @UseCheckpoint = 1).

DECLARE @TotalRowCount BIGINT = (SELECT COUNT(*) FROM dbo.MyTable WHERE Id >= @MinID AND Id <= @MaxID);

DECLARE @AffectedRowsInBatch INT = @BatchSize;
DECLARE @TotalProcessedRows BIGINT = 0;
DECLARE @ProgressMessage NVARCHAR(MAX);
DECLARE @ProgressPercentage INT;
DECLARE @QueryStartTime DATETIME2 = SYSDATETIME();
DECLARE @BatchStartTime DATETIME2;
DECLARE @BatchCounter INT = 0;
DECLARE @CheckpointErrorMessage NVARCHAR(4000);

RAISERROR (N'Process starting...', 0, 1) WITH NOWAIT;

WHILE (@AffectedRowsInBatch > 0 AND (@MaxBatchesToProcess = 0 OR @BatchCounter < @MaxBatchesToProcess) AND @MinID <= @MaxID)
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        SET @BatchStartTime = SYSDATETIME();
        SET @BatchCounter = @BatchCounter + 1;

        -- Insert batch of rows into the tracking table
        INSERT INTO [BulkProcessTracking].[yyyyMMddHHmm_Tracker] WITH (TABLOCK) (ID)
        SELECT TOP (@BatchSize) mt.Id
        FROM dbo.MyTable AS mt
        WHERE
            mt.Id >= @MinID AND mt.Id <= @MaxID
        ORDER BY mt.Id;

        SET @AffectedRowsInBatch = @@ROWCOUNT;
        COMMIT TRANSACTION;

        -- Update the MinID for the next batch to start from the next unprocessed Id
        SET @MinID = (SELECT ISNULL(MAX(ID), @MinID) + 1 FROM [BulkProcessTracking].[yyyyMMddHHmm_Tracker]);

        -- Update progress counters
        SET @TotalProcessedRows = @TotalProcessedRows + @AffectedRowsInBatch;
        SET @ProgressPercentage = CASE WHEN @TotalRowCount > 0 THEN (CAST(@TotalProcessedRows AS BIGINT) * 100) / @TotalRowCount ELSE 100 END;

        -- Calculate and print progress
        SET @ProgressMessage = FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff') +
            N' [' + FORMAT(@BatchCounter,'0000000') +']' +
            N' [Duration: ' + FORMAT(DATEADD(MILLISECOND, DATEDIFF_BIG(MILLISECOND, @QueryStartTime, SYSDATETIME()), 0), 'HH:mm:ss.fff') + ']' +
            N' [Elapsed: ' + FORMAT(DATEADD(MILLISECOND, DATEDIFF_BIG(MILLISECOND, @BatchStartTime, SYSDATETIME()), 0), 'HH:mm:ss.fff') + ']' +
            N' [Processed: '  + FORMAT(@AffectedRowsInBatch,'0,0') + ']' +
            N' [TotalProcessed: '  + FORMAT(@TotalProcessedRows,'0,0') + ' / ' + FORMAT(@TotalRowCount,'N0') + ']' +
            N' [Progress: %d%%]';
        RAISERROR (@ProgressMessage, 0, 1, @ProgressPercentage) WITH NOWAIT;

        -- Perform a checkpoint after every n batches to minimize the transaction log size (only in SIMPLE recovery)
        IF (@UseCheckpoint = 1 AND @BatchCounter % @BatchesPerCheckpoint = 0)
        BEGIN
            BEGIN TRY
                RAISERROR (N'Checkpoint', 0, 1) WITH NOWAIT;
                CHECKPOINT;
            END TRY
            BEGIN CATCH
                SET @CheckpointErrorMessage = ERROR_MESSAGE();
                RAISERROR('Checkpoint failed: %s', 0, 1, @CheckpointErrorMessage) WITH NOWAIT;
            END CATCH
        END

        -- Slight delay between batches to minimize the impact on other operations in a busy environment.
        WAITFOR DELAY '00:00:00.100';
    END TRY
    BEGIN CATCH
        -- TODO: `The ROLLBACK TRANSACTION request has no corresponding BEGIN TRANSACTION.` will be thrown if the error occurs after the commit transaction above, such as `Divide by zero error encountered.`
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
        -- DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        -- DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        -- DECLARE @ErrorState INT = ERROR_STATE();
        -- RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        -- BREAK;
    END CATCH
END
