CREATE OR ALTER PROCEDURE dbo.RAG_GPT_ANSWER
(
    @query NVARCHAR(MAX),
    @topK INT = 5,
    @answer NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------------------
    -- Step 0: Validate Top-K
    ---------------------------------------------------------------------
    IF @topK IS NULL OR @topK < 1 
        SET @topK = 5;

    IF @topK > 50 
        SET @topK = 50;   -- prevent massive retrieval / memory pressure

    ---------------------------------------------------------------------
    -- Step 1: Embed the question
    ---------------------------------------------------------------------
    DECLARE @qVec VECTOR(1536);

    EXEC dbo.GET_EMBEDDINGS
        @model = 'text-embedding-3-small',
        @text  = @query,
        @embedding = @qVec OUTPUT;

    ---------------------------------------------------------------------
    -- Step 2: Retrieve Top-K Similar Documents and build context
    ---------------------------------------------------------------------
    DECLARE @context NVARCHAR(MAX) = N'';

    SELECT TOP (@topK)
           @context = @context +
               N'--- Review #' + CAST(DocumentId AS NVARCHAR(20)) + CHAR(10) +
               N'User: ' + ISNULL(userName,'Unknown') + CHAR(10) +
               N'Score: ' + CAST(ISNULL(score,0) AS NVARCHAR(10)) + CHAR(10) +
               N'Review: ' + ISNULL(Content,'') + CHAR(10) + CHAR(10)
    FROM dbo.DocumentsRag
    ORDER BY VECTOR_DISTANCE('cosine', Embedding, @qVec);

    ---------------------------------------------------------------------
    -- Step 2.5: Safety: ensure context is not NULL
    ---------------------------------------------------------------------
    IF @context IS NULL SET @context = N'';

    ---------------------------------------------------------------------
    -- Step 3: Escape content and build JSON payload manually
    -- We must escape double quotes and convert newlines to \n for JSON strings
    ---------------------------------------------------------------------
    DECLARE @contextEscaped NVARCHAR(MAX);
    DECLARE @queryEscaped NVARCHAR(MAX);
    DECLARE @systemMsg NVARCHAR(MAX) = N'You are a helpful assistant. Use ONLY the provided reviews as information.';

    -- replace CR, LF, and double quotes for safe embedding in JSON string values
    SET @contextEscaped = REPLACE(REPLACE(REPLACE(@context, CHAR(13), N''), CHAR(10), N'\n'), '"', '\"');
    SET @queryEscaped   = REPLACE(REPLACE(REPLACE(@query,   CHAR(13), N''), CHAR(10), N'\n'), '"', '\"');
    SET @systemMsg      = REPLACE(@systemMsg, '"', '\"');

    -- Construct the user message content (escaped)
    DECLARE @userContent NVARCHAR(MAX) = CONCAT('Query: ', @queryEscaped, '\nContext from retrieved reviews:\n', @contextEscaped);

    -- Build final JSON payload as NVARCHAR(MAX)
    DECLARE @payload NVARCHAR(MAX) =
        CONCAT(
            '{',
                '"messages": [',
                    '{"role":"system","content":"', @systemMsg, '"},',
                    '{"role":"user","content":"', @userContent, '"}',
                '],',
                '"max_tokens": 600,',
                '"temperature": 0.2',
            '}'
        );

    ---------------------------------------------------------------------
    -- Step 4: Call Azure OpenAI via sp_invoke_external_rest_endpoint
    ---------------------------------------------------------------------
    DECLARE @response NVARCHAR(MAX);

    EXEC sys.sp_invoke_external_rest_endpoint
        @url = 'https://finetune2219.openai.azure.com/openai/deployments/gpt-5-chat/chat/completions?api-version=2025-01-01-preview',
        @method = 'POST',
        @payload = @payload,
        @headers = '{"Content-Type": "application/json","api-key": "BWgnH81KChoHwNyOiEEisJcaNmQpv93R8PlsujRmXO3xwAKN4BgmJQQJ99BJACfhMk5XJ3w3AAABACOGQQB0"}',
        @response = @response OUTPUT;

    ---------------------------------------------------------------------
    -- Step 5: Extract assistant's text (adjust JSON path if necessary)
    ---------------------------------------------------------------------
    -- The OpenAI/Azure response shape may vary by API version; adjust path if different.
    SELECT @answer = JSON_VALUE(@response, '$.result.choices[0].message.content');

    -- Fallback: if first path yields NULL, try a common alternative path
    IF @answer IS NULL
    BEGIN
        SELECT @answer = JSON_VALUE(@response, '$.choices[0].message.content');
    END

END
GO
