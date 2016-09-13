
CREATE FUNCTION [dbo].[SplitInTableWId](@text varchar(MAX))
RETURNS @Strings TABLE (id int, txt varchar(200))
AS
BEGIN
	DECLARE @id INT=0
	DECLARE @index INT
	SET @index = -1

	WHILE (LEN(ISNULL(@text,'')) > 0)
	BEGIN
		SET @index = CHARINDEX(',', @text)
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
		SET @text = RIGHT(@text, (LEN(@text) - @index))
	END
	RETURN
END

