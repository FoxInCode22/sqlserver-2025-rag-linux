CREATE PROCEDURE [dbo].[GET_EMBEDDINGS]
(
    @model VARCHAR(MAX),
    @text NVARCHAR(MAX),
    @embedding VECTOR(1536) OUTPUT
)
AS
BEGIN
    DECLARE @retval INT, @response NVARCHAR(MAX);
    DECLARE @url VARCHAR(MAX);
    DECLARE @payload NVARCHAR(MAX) = JSON_OBJECT('input': @text);
 
    -- Set the @url variable with proper concatenation before the EXEC statement
    SET @url = 'https://<resourcename>.openai.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-05-15';
 
    EXEC dbo.sp_invoke_external_rest_endpoint 
        @url = @url,
        @method = 'POST',   
        @payload = @payload,   
        @headers = '{"Content-Type":"application/json", "api-key":"<key>"}', 
        @response = @response OUTPUT;
 
    -- Use JSON_QUERY to extract the embedding array directly
    DECLARE @jsonArray NVARCHAR(MAX) = JSON_QUERY(@response, '$.result.data[0].embedding');
 
    
    SET @embedding = CAST(@jsonArray as VECTOR(1536));
END
GO
