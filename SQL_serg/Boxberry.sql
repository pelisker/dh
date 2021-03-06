
declare	@object int


--Инициализация служебных переменных
DECLARE 
	@domen varchar(100),
	@user_login varchar(100),
	@user_hash varchar(100),
	@url varchar(max),
	@proxy varchar(30)=NULL, 
	@output nvarchar(max),
	@hr int,
	@status int, 
	@POST nvarchar(max),
	@Src varchar(255), 
	@Desc varchar(255);
	DECLARE @Response TABLE (response varchar(max))

	--DECLARE @xml_response xml, 
	--SET TEXTSIZE 2147483647;

	SET @domen=(SELECT value FROM AmoSettings WHERE [Key]='domen')
	SET @user_login=(SELECT value FROM AmoSettings WHERE [Key]='USER_LOGIN')
	SET @user_hash=(SELECT value FROM AmoSettings WHERE [Key]='USER_HASH')

	--Инициализация соединения
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
	SET @url='http://api.boxberry.de/json.php?token=38472.pjpqfced&method=ListPoints&CityCode=68&prepaid=0'
	SET @url='http://api.boxberry.de/json.php?token=38472.pjpqfced&method=ListCities'
	EXEC @hr = sp_OAMethod @object, 'open',NULL, 'GET', @url, 'False'
	IF @hr <> 0 GOTO CLEANUP
	EXEC @hr = sp_OAMethod @object, 'SetRequestHeader', NULL, 'content-type', 'application/x-www-form-urlencoded; charset=windows-1251;'
	IF @hr <> 0 GOTO CLEANUP
--	SET @POST='USER_LOGIN='+@user_login+'&USER_HASH='+@user_hash
	EXEC @hr = sp_OAMethod @object, 'send',NULL, @POST
	IF @hr <> 0 GOTO CLEANUP
	EXEC @hr = sp_OAGetProperty @object, 'status', @status OUT
	IF @hr <> 0 GOTO CLEANUP
	If @Status = 200
	BEGIN
		--Вставляем результат процедуры в таблицу, передача XML через строковый параметр с OUTPUT не работает.
		INSERT @Response
		EXEC @hr = sp_OAGetProperty @object,'ResponseText'
declare @resp varchar(max)
select @resp=response from @Response
--print dbo.replaceUnicode(@resp)


select * into #test from parseJSON(dbo.replaceUnicode(@resp)) d

		IF @hr <> 0 GOTO CLEANUP
		ELSE
			GOTO THEEND
	END
	ELSE	
	BEGIN
		SELECT @output='Error: Status '+CAST(@status AS varchar);
		GOTO CLEANUP
	END




	CLEANUP:
		EXEC sp_OAGetErrorInfo @object, @src OUT, @desc OUT 
		raiserror('Ошибка процедуры авторизации на сервере 0x%x, %s, %s',16,1, @hr, @src, @desc)
		EXEC sp_OADestroy @object
		print 1
	THEEND:
		print 0
--239

--drop taBLE #test
select * from #test where stringvalue like 'москва%'

--select * from #test where parent_id=306
