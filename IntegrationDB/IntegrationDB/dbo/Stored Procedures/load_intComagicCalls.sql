CREATE PROCEDURE [dbo].[load_intComagicCalls]
@date1 datetime,
@date2 datetime
AS

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
	SET @url='https://api.comagic.ru/api/login/'
	EXEC @hr = sp_OAMethod @object, 'open',NULL, 'POST', @url, 'False'
	IF @hr <> 0 GOTO CLEANUP

	EXEC @hr = sp_OAMethod @object, 'SetRequestHeader', NULL, 'content-type', 'application/x-www-form-urlencoded; charset=windows-1251;'
	IF @hr <> 0 GOTO CLEANUP


	EXEC @hr = sp_OAMethod @object, 'send',NULL,'login=comagic@silversite.ru&password=kuy1r32dfg'
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
	--select 1, @output

	
	set @ssid=SUBSTRING(@output,27,32)
	SET @url ='https://api.comagic.ru/api/v1/call/?session_key='+@ssid+'&customer_id='+@client_id+'&site_id='+@site_id+'&date_from='+@date_from+'&date_till='+@date_till

	EXEC @hr = sp_OAMethod @object, 'open',NULL, 'GET', @url, 'False'
	IF @hr <> 0 GOTO CLEANUP
	EXEC @hr = sp_OAMethod @object, 'send',NULL
	IF @hr <> 0 GOTO CLEANUP
	EXEC @hr = sp_OAGetProperty @object, 'status', @status OUT
	IF @hr <> 0 GOTO CLEANUP
	If @Status = 200
	BEGIN
		--Вставляем результат процедуры в таблицу, передача XML через строковый параметр с OUTPUT не работает.
		delete from @Response
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
	
	--select @output
	
--id ID обращения
--call_date Дата-время обращения
--numa Телефон
--visitor_id номер абонента
--duration длительность звонка
--ac_id рекламная камания - в рамках комеджика все юзеры делятся по сегментам (кампаниям)
--utm_source
--utm_medium
--utm_term
--utm_content
--referrer реферер
--city город
	
	--DECLARE @field varchar(100)='"utm_content"'	
	--;WITH 
	--pre_content AS (SELECT * FROM SplitInTableWIdD(@output,'{') WHERE id>1),
	--content AS (select RIGHT(txt, LEN(txt)-CHARINDEX(@field,txt)-LEN(@field)) AS txt FROM pre_content)
	--select LEFT(txt, CHARINDEX(',',txt)-1) as f1, * from content

	--SELECT * 
	--FROM parseJSON(@output) WHERE name IN ('id','call_date','numa','visitor_id','duration','ac_id','utm_source','utm_medium','utm_term','utm_content','referrer','city')


	SELECT * INTO #content
	FROM parseJSON(@output) WHERE name IN ('id','call_date','numa','visitor_id','duration','ac_id','utm_source','utm_medium','utm_term','utm_content','referrer','city')
	

	--Убираем символы unicode
	UPDATE #content SET stringvalue=dbo.replaceUnicode(stringvalue)

--return

	--SELECT * FROM #content where stringvalue like '%\u%'
	--;WITH 
	--content AS (
	--	SELECT * 
	--	FROM parseJSON(@output) WHERE name IN ('id','call_date','numa','visitor_id','duration','ac_id','utm_source','utm_medium','utm_term','utm_content','referrer','city')
	--	)
	--select * from
	--(SELECT c.name+',' FROM content c for xml path('')) as ex
	
--	DECLARE @intComagicCalls TABLE (
--	[ac_id] int,
--	[call_date] [datetime] ,
--	[city] [varchar](50),
--	[duration] [int] ,
--	[id] [int],
--	[numa] [varchar](20) ,
--	[referrer] [varchar](50) ,
--	[utm_content] [varchar](50) ,
--	[utm_medium] [varchar](50) ,
--	[utm_source] [varchar](50) ,
--	[utm_term] [varchar](50) ,
--	[visitor_id] [int]
--)
	--select * FROM intComagicCalls WHERE call_date BETWEEN @date1 AND @date2
	--DELETE FROM intComagicCalls WHERE call_date BETWEEN @date1 AND @date2
	INSERT INTO intComagicCalls ([ac_id],[call_date],[city],[duration],[id],[numa],[referrer],
				[utm_content],[utm_medium],[utm_source],[utm_term],[visitor_id])
	--exec sp_CrossW '#content', 'Parent_ID', 'PID', 'name', 'StringValue',''
	SELECT data.* FROM
	(SELECT
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'ac_id' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS int) END
			ELSE NULL
		  END) AS [ac_id],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'call_date' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN null ELSE CONVERT(datetime,StringValue,120) END
			ELSE NULL
		  END) AS [call_date],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'city' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS varchar(50)) END
			ELSE NULL
		  END) AS [city],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'duration' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS int) END
			ELSE NULL
		  END) AS [duration],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'id' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS int) END
			ELSE NULL
		  END) AS [id],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'numa' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS varchar(50)) END
			ELSE NULL
		  END) AS [numa],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'referrer' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS varchar(50)) END
			ELSE NULL
		  END) AS [referrer],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'utm_content' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS varchar(500)) END
			ELSE NULL
		  END) AS [utm_content],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'utm_medium' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS varchar(50)) END
			ELSE NULL
		  END) AS [utm_medium],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'utm_source' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS varchar(50)) END
			ELSE NULL
		  END) AS [utm_source],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'utm_term' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS varchar(50)) END
			ELSE NULL
		  END) AS [utm_term],
	  MAX(CASE CAST(name AS NVARCHAR(100))
			WHEN N'visitor_id' THEN CASE ltrim(rtrim(StringValue)) WHEN 'null' THEN NULL ELSE CAST(StringValue AS varchar(50)) END
			ELSE NULL
		  END) AS [visitor_id]
	FROM #content
	GROUP BY Parent_ID
	--ORDER BY Parent_ID
	) data
	LEFT JOIN intComagicCalls cc ON data.id=cc.id
	WHERE ISNULL(cc.id,0)=0
	
	
--	select * from @intComagicCalls
	
	--select F from T 
	--INNER JOIN  objs o ON c.parent_id=o.object_id
	--WHERE c.name IN ('id','call_date','numa','visitor_id','duration','ac_id','utm_source','utm_medium','utm_term','utm_content','referrer','city')

	--WHERE 
	--sequenceNo=0 AND 
	--parent_id not in (SELECT distinct parent_ID 
	--FROM content WHERE name='id')
	DROP TABLE #content

	--Завершение сессии 	
	SET @url ='https://api.comagic.ru/api/logout/?session_key='+@ssid
	EXEC @hr = sp_OAMethod @object, 'open',NULL, 'GET', @url, 'False'
	IF @hr <> 0 GOTO CLEANUP
	EXEC @hr = sp_OAMethod @object, 'send',NULL
	IF @hr <> 0 GOTO CLEANUP
	EXEC @hr = sp_OAGetProperty @object, 'status', @status OUT
	IF @hr <> 0 GOTO CLEANUP
	If @Status = 200
	BEGIN
		--Вставляем результат процедуры в таблицу, передача XML через строковый параметр с OUTPUT не работает.
		delete from @Response
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