USE [Integration]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		SC
-- Create date: 19.08.16
-- Description:	Обновление остатков на сайте через API. Каждые 5 секунд. 
-- =============================================
ALTER PROCEDURE [dbo].[PushSiteOstat]
AS
BEGIN
	SET NOCOUNT ON;

DECLARE
	@id int=1,
	@lastDate datetime,
	@json nvarchar(2000)='{"key":"64011b8d6c9c7d3d4ddf826a5737a1d0","tovars": [',
	@row_cnt tinyint
		
	IF not exists(SELECT * FROM intJobState WHERE code=@id)
		INSERT INTO intJobState (code,Name,lastDate) VALUES (@id ,'Обновление остатка на сайте.', GETDATE())


	
	SELECT @lastDate=ISNULL(lastDate,GETDATE()) FROM intJobState WHERE code=@id 

	SELECT top 10 tovar, quantity=SUM(quantity) INTO #log 
	FROM uchet.dbo.ostatq_hist 
	WHERE date>@lastDate AND account='29' AND lot=0 AND company NOT IN (116) 
	GROUP BY tovar
	--ORDER BY date 
	
	SET @row_cnt=@@ROWCOUNT
	IF @row_cnt=0
		BEGIN
			UPDATE intJobState 
			SET lastRun=GETDATE(), Result='Обновлено 0 записей'
			WHERE code=@id 
			return
		END
	ELSE
		BEGIN
			SELECT @json=@json+N' 
{"articul": '+CAST(tovar AS varchar(10))+', "quantity": '+ CAST(quantity AS varchar(10))+', "way": '+ CAST(quantity AS varchar(10))+'},'
			FROM #log
			GROUP BY tovar

			SET @json=LEFT(@json,LEN(@json)-1)+N'
]}'
			print @json
			
			UPDATE intJobState 
			SET lastRun=GETDATE(), lastDate=(SELECT top 1 date FROM #log ORDER BY DATE desc), Result='Обновлено ' +CAST(@row_cnt AS varchar(10))+' записей', success=1
			WHERE code=@id 
		END
		
	
--Пример json массива
--{
--	"contents": [
--		{"productID": 34,"quantity": 1},
--		{"productID": 56,"quantity": 3}
--	]
-- }

return

DECLARE
@date1 datetime,
@date2 datetime


DECLARE 
	@url varchar(max),
	@proxy varchar(30)=NULL, 
	@region int,  
	@output nvarchar(max),
	@client_id varchar(10)='14509',
	@site_id varchar(10)='10991',
	@date_from varchar(20) = REPLACE(CONVERT(varchar(20),@date1,120),' ','%20'),
	@date_till varchar(20)= REPLACE(CONVERT(varchar(20),@date2,120),' ','%20'),
	@object int, 
	@hr int,
	@ssid varchar(100),
	@status int, 
	@rt char(200), 
	@doc varchar(max)
	DECLARE @Response TABLE (response varchar(max))
	DECLARE @Source varchar(255), @Desc varchar(255);

	SET @date1=ISNULL(@date1,GETDATE())
	SET @date2=ISNULL(@date2,GETDATE())

--Пример работы с web сервисом
--http://www.sql.ru/forum/576338/konnektor-k-veb-sluzhbam-ms-sql-2000?hl=sp_oacreate#5988363

	SET TEXTSIZE 2147483647;
	--Инициализация соединения
	--EXEC @hr = sp_OACreate 'msxml2.xmlhttp.3.0', @object OUT;
	--EXEC @hr = sp_OACreate 'MSXML2.ServerXMLHTTP', @object OUT;
	EXEC @hr = sp_OACreate 'WinHttp.WinHttpRequest.5.1', @object OUT;
	IF @hr <> 0 GOTO CLEANUP
	--Отключение проверки сертификата
	exec @hr = sp_OASetProperty @object, 'Option', '13056', 4
	IF @hr <> 0 GOTO CLEANUP
	--Установка свойства User Agent
	exec @hr = sp_OASetProperty @object, 'Option', 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; WOW64; Trident/4.0; chromeframe; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; .NET4.0C; InfoPath.3; .NET4.0E)', 0
	IF @hr <> 0 GOTO CLEANUP
	--Установка прокси
	IF @proxy IS NOT NULL
	BEGIN
		EXEC @hr = sp_OAMethod @object, 'setProxy',NULL, 2, @proxy
		IF @hr <> 0 GOTO CLEANUP
	END
	EXEC @hr = sp_OAMethod @object, 'SetTimeouts',NULL, 30000, 30000, 30000, 30000	
	IF @hr <> 0 GOTO CLEANUP
	
	--Логин
	SET @url='http://deephouse.pro/update_ost.php'
	EXEC @hr = sp_OAMethod @object, 'open',NULL, 'POST', @url, 'False'
	IF @hr <> 0 GOTO CLEANUP

	EXEC @hr = sp_OAMethod @object, 'SetRequestHeader', NULL, 'content-type', 'application/x-www-form-urlencoded; charset=utf-8;'
	IF @hr <> 0 GOTO CLEANUP

	DECLARE @send nvarchar(max)='{"key":"64011b8d6c9c7d3d4ddf826a5737a1d0","product":[{"articul":49758,"quantity":18,"way":0},{"articul":49758,"quantity":18,"way":1}]}'
	--N'{"key":"64011b8d6c9c7d3d4ddf826a5737a1d0","product":{"articul":49758,"quantity":18},{"articul":49758,"quantity":18}}'
	--'{"Name":"Oleg","last_name":"Ivanov","amount":2}'
	--'"Content"="key"=64011b8d6c9c7d3d4ddf826a5737a1d0,"product"=array(array("articul"=49758,"quantity"=18,"way"=0),array("articul"=49758,"quantity"=18,"way"=0))'

	EXEC @hr = sp_OAMethod @object, 'send', NULL, @send
	IF @hr <> 0 GOTO CLEANUP
	
	EXEC @hr = sp_OAGetProperty @object, 'status', @status OUT
	IF @hr <> 0 GOTO CLEANUP
	If @Status = 200
	BEGIN
		--Вставляем результат процедуры в таблицу, передача XML через строковый параметр с OUTPUT не работает.
		INSERT @Response
		EXEC @hr = sp_OAGetProperty @object,'ResponseText'
		IF @hr <> 0 GOTO CLEANUP
	END
	ELSE	
	BEGIN
		SELECT @output='Error: Status '+CAST(@status AS varchar);
		GOTO CLEANUP
	END
	set @output=(select CAST(response AS nvarchar(max)) from @Response)
	select 1, @output

	
	--set @ssid=SUBSTRING(@output,27,32)
	--SET @url ='https://api.comagic.ru/api/v1/call/?session_key='+@ssid+'&customer_id='+@client_id+'&site_id='+@site_id+'&date_from='+@date_from+'&date_till='+@date_till

	--EXEC @hr = sp_OAMethod @object, 'open',NULL, 'GET', @url, 'False'
	--IF @hr <> 0 GOTO CLEANUP
	--EXEC @hr = sp_OAMethod @object, 'send',NULL
	--IF @hr <> 0 GOTO CLEANUP
	--EXEC @hr = sp_OAGetProperty @object, 'status', @status OUT
	--IF @hr <> 0 GOTO CLEANUP
	--If @Status = 200
	--BEGIN
	--	--Вставляем результат процедуры в таблицу, передача XML через строковый параметр с OUTPUT не работает.
	--	delete from @Response
	--	INSERT @Response
	--	EXEC @hr = sp_OAGetProperty @object,'ResponseText'
	--	IF @hr <> 0 GOTO CLEANUP
	--END
	--ELSE	
	--BEGIN
	--	SELECT @output='Error: Status '+CAST(@status AS varchar);
	--	GOTO CLEANUP
	--END
	--set @output=(select CAST(response AS nvarchar(max)) from @Response)
	
	--select @output

	----Завершение сессии 	
	--SET @url ='https://api.comagic.ru/api/logout/?session_key='+@ssid
	--EXEC @hr = sp_OAMethod @object, 'open',NULL, 'GET', @url, 'False'
	--IF @hr <> 0 GOTO CLEANUP
	--EXEC @hr = sp_OAMethod @object, 'send',NULL
	--IF @hr <> 0 GOTO CLEANUP
	--EXEC @hr = sp_OAGetProperty @object, 'status', @status OUT
	--IF @hr <> 0 GOTO CLEANUP
	--If @Status = 200
	--BEGIN
	--	--Вставляем результат процедуры в таблицу, передача XML через строковый параметр с OUTPUT не работает.
	--	delete from @Response
	--	INSERT @Response
	--	EXEC @hr = sp_OAGetProperty @object,'ResponseText'
	--	IF @hr <> 0 GOTO CLEANUP
	--END
	--ELSE	
	--BEGIN
	--	SELECT @output='Error: Status '+CAST(@status AS varchar);
	--	GOTO CLEANUP
	--END
	--set @output=(select CAST(response AS nvarchar(max)) from @Response)
	
	Print 'OK'
	
	EXEC @hr = sp_OADestroy @Object;
	IF @hr <> 0 GOTO CLEANUP
	GOTO ENDP
	
	CLEANUP:
	-- Check whether an error occurred.
	IF @HR <> 0
	BEGIN
		-- Report the error.
		EXEC sp_OAGetErrorInfo @Object,
			@Source OUT,
			@Desc OUT;
		SELECT @output='Error, '+@Desc;
	END

	-- Destroy the object.
	BEGIN
		EXEC @HR = sp_OADestroy @Object;
		-- Check if an error occurred.
		IF @HR <> 0 
		BEGIN
			-- Report the error.
			EXEC sp_OAGetErrorInfo @Object,
			@Source OUT,
			@Desc OUT;
			SELECT @output='Error, '+@Desc;
		END
	END
	PRINT @output
	RETURN 1
	
	ENDP:
		PRINT 'END'
		Return 0


 --   MERGE intManager AS target
 --   USING (SELECT dog.[code]
	--	  ,name=ISNULL(dog.name,'')
	--	  ,email=pp.email
	--FROM [uchet].[dbo].dogovor dog
	--INNER JOIN [uchet].[dbo].dogovor folder
	--	ON dog.upcode=folder.code
	--INNER JOIN [uchet].[dbo].[passwordparam] pp
	--	ON dog.code=CAST(CASE CHARINDEX(',',pp.dogovor) WHEN 0 THEN pp.dogovor ELSE SUBSTRING(pp.dogovor,0,CHARINDEX(',',pp.dogovor)) END AS int)
	--INNER JOIN [uchet].[dbo].[password] p
	--	ON pp.upcode=p.code
	--WHERE 
	--	folder.upcode=1 AND
	--	p.arm!=5
	--) AS source (code, name, email)
 --   ON (target.code = source.code)
 --   WHEN MATCHED THEN 
 --       UPDATE SET name=source.name, email=source.email
	--WHEN NOT MATCHED THEN	
	--    INSERT (code, name, email)
	--    VALUES (source.code, source.name, source.email)
	--WHEN NOT MATCHED BY SOURCE THEN	
	--	DELETE;


END


GO

