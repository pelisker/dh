CREATE FUNCTION [dbo].[SplitInTableWIdD](@text varchar(MAX), @devider VARCHAR(MAX))
RETURNS @Strings TABLE (id int, txt VARCHAR(MAX))
AS
BEGIN
	DECLARE @id INT=0, @len INT
	DECLARE @index INT
	SET @index = -1
	SET @len = DATALENGTH(@devider)

	WHILE (DATALENGTH(ISNULL(@text,'')) > 0)
	BEGIN
		SET @index = CHARINDEX(@devider, @text)
		IF (@index = 0)-- AND (LEN(@text) > 0)
		BEGIN
			INSERT INTO @Strings VALUES (@id, @text)
			BREAK
		END
		IF (@index >= 1)
		BEGIN
			INSERT INTO @Strings VALUES (@id, LEFT(@text, @index - 1))
			SET @id=@id+1
		END
		SET @text = RIGHT(@text, (DATALENGTH(@text) - @index - @len + 1))
	END
	RETURN
END
