DECLARE @BatchSize INT = 50;
DECLARE @minId INT, @maxId INT, @startId INT, @endId INT;

SELECT @minId = MIN(DocumentId), @maxId = MAX(DocumentId) FROM dbo.DocumentsRag;
SET @startId = @minId;

WHILE @startId <= @maxId
BEGIN
    SET @endId = @startId + @BatchSize - 1;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT DocumentId, Content
    FROM dbo.DocumentsRag
    WHERE DocumentId BETWEEN @startId AND @endId
      AND Embedding IS NULL;

    OPEN cur;
    DECLARE @id INT, @txt NVARCHAR(MAX), @vec VECTOR(1536);

    FETCH NEXT FROM cur INTO @id, @txt;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC dbo.GET_EMBEDDINGS
                @model = 'text-embedding-3-small',
                @text = @txt,
                @embedding = @vec OUTPUT;

            UPDATE dbo.DocumentsRag SET Embedding = @vec WHERE DocumentId = @id;
        END TRY
        BEGIN CATCH
            PRINT 'Error embedding DocumentId=' + CAST(@id AS NVARCHAR(20))
                + ' : ' + ERROR_MESSAGE();
        END CATCH;

        FETCH NEXT FROM cur INTO @id, @txt;
    END

    CLOSE cur;
    DEALLOCATE cur;

    SET @startId = @endId + 1;
END
GO
