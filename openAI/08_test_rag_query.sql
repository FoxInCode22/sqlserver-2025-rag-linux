DECLARE @answer NVARCHAR(MAX);
EXEC dbo.RAG_GPT_ANSWER
    @query = N'What billing problems do users frequently report?',
    @topK = 5,
    @answer = @answer OUTPUT;
SELECT @answer AS GPT_Answer;