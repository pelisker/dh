--select * from cllc_gright where upcode=0
--SELECT note FROM doc_ref WHERE type_doc='СчМК'
--SELECT * FROM intComagicCalls

	DECLARE @id int
	,@phoneNumber varchar(20)
	,@clientID int
	,@call_date datetime
	,@duration int
	,@ac_id int
	,@visitor_id int
	,@utm_source varchar(50)
	,@utm_medium varchar(50)
	,@utm_term varchar(50)
	,@utm_content varchar(500)
	,@referrer varchar(100)
	,@city varchar(50)

	SELECT top 1 
		@id=id, 
		@phoneNumber=numa,
		@call_date = call_date,
		@visitor_id=visitor_id,
		@duration=duration,
		@ac_id=ac_id,
		@utm_source=utm_source,
		@utm_medium=utm_medium,
		@utm_term=utm_term,
		@utm_content=utm_content,
		@referrer=referrer,
		@city=city
	FROM intComagicCalls WHERE sv=0 ORDER BY call_date DESC
	IF @id IS NULL
		--RETURN 0
		PRINT 0

	--Тестовые значения
	--SET @phoneNumber='9165750202'
	--SET @id=100
	
	SELECT 
		@clientID=c.code 
	FROM 
		uchet.dbo.company c (NOLOCK) 
	WHERE 
		upcode IN (SELECT code FROM uchet.dbo.company (NOLOCK) WHERE upcode=276)
	AND LEFT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone,'.','') ,':','') ,'тел','') ,' ','') ,')','') ,'(','') ,'-',''),'+7','8'),11)='8'+@phoneNumber
	
	--Если клиент не найден, то проставляется неизвестный клиент.
	SET @clientID=ISNULL(@clientID,1501)
	
	--SELECT * FROM uchet.dbo.company WHERE code=@clientID
	
	exec uchet.dbo.InitProcess 278,0
	declare @drcode table (code int)
	
	INSERT INTO uchet.dbo.doc_ref (owner, type_doc, nn, date, date2, dogovor, c_from, c_to, serial, total)
	OUTPUT inserted.code INTO @drcode
	SELECT
		owner	= 23,
		type_doc= 'ЛИД',
		nn		= CAST(@id AS varchar(15)),
		date	= CAST(@call_date AS date),
		date2	= @call_date,
		dogovor	= 0,
		c_from	= 230,
		c_to	= @clientID,
		serial	= '',
		total	= 0
	
	UPDATE uchet.dbo.DrfOrder
		SET 
			TelephonyID=@id,
			TelDuration=@duration,
			TelVisitorID=@Visitor_ID,
			TelAcID=@ac_id,
			TelUtmSource=@utm_source,
			TelUtmMedium=@utm_medium,
			TelUtmTerm=@utm_term,
			TelUtmContent=@utm_content,
			TelReferrer=@referrer,
			TelCity=@city
	WHERE 
		upcode IN (SELECT code FROM @drcode)

	UPDATE [Integration].[dbo].[intComagicCalls]
	SET sv=1
	WHERE 
		@id=id AND @phoneNumber=numa AND @call_date = call_date

	
	DELETE FROM uchet.dbo.process WHERE code=@@SPID
	
	
	--select * from uchet.dbo.drfparam where upcode IN (SELECT code FROM @drcode)
	--select * from uchet.dbo.drforder where upcode IN (SELECT code FROM @drcode)


--update intComagicCalls
--set sv=0
--where call_date>'18.02.2016'
