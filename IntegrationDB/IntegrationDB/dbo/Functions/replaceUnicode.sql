-- =============================================
-- Author:		СЧ
-- Create date: 16.02.16
-- Description:	Подменяет коды юникода в строке на нормальные символы. При этом не трогает символы не в юникоде. Пример 'ап\u043f\u043b'-> 'аппл'. 
-- =============================================
CREATE FUNCTION replaceUnicode
( @S VARCHAR(max)
)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @position int=0, @char char, @res_str nvarchar(max)=''

	WHILE @position <= DATALENGTH(@S)
	BEGIN
		SET @char=SUBSTRING(@S, @position, 1)
		IF @char='\'
		BEGIN		
			SET @res_str=@res_str+NCHAR(CONVERT(varbinary(100),REPLACE(SUBSTRING(@S, @position, 6),'\u',''),2))
			SELECT @position = @position + 6;
		END
		ELSE
		BEGIN
			SET @res_str=@res_str+@char
			SELECT @position = @position + 1;
		END
	END
	RETURN @res_str

END
