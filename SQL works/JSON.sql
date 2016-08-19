DECLARE
@date1 datetime='01.02.2016 00:00:00',
@date2 datetime='01.02.2016 23:59:59'

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
	SET @url='https://api.comagic.ru/api/login/?login=comagic@silversite.ru&password=Chegevara1981'
	EXEC @hr = sp_OAMethod @object, 'open',NULL, 'POST', @url, 'False'
	IF @hr <> 0 GOTO CLEANUP

	EXEC @hr = sp_OAMethod @object, 'SetRequestHeader', NULL, 'content-type', 'text/html; charset=windows-1251;'
	IF @hr <> 0 GOTO CLEANUP


	EXEC @hr = sp_OAMethod @object, 'send',NULL
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


	SELECT * INTO #content
	FROM parseJSON(@output) WHERE name IN ('id','call_date','numa','visitor_id','duration','ac_id','utm_source','utm_medium','utm_term','utm_content','referrer','city')
	
	UPDATE #content SET stringvalue=dbo.replaceUnicode(stringvalue)

	--SELECT * FROM #content where stringvalue like '%\u%'
	--;WITH 
	--content AS (
	--	SELECT * 
	--	FROM parseJSON(@output) WHERE name IN ('id','call_date','numa','visitor_id','duration','ac_id','utm_source','utm_medium','utm_term','utm_content','referrer','city')
	--	)
	--select * from
	--(SELECT c.name+',' FROM content c for xml path('')) as ex
	
	exec sp_CrossW '#content', 'Parent_ID', 'PID', 'name', 'StringValue',''
	
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
	
	select 99, @output	
	
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
	
	ENDP:
		SELECT @output
		PRINT 'Finish'