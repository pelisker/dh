-- =============================================
-- Author:		СЧ
-- Create date: 18.02.16
-- Description:	Загрузка лидов в СВ
-- =============================================
CREATE PROCEDURE [dbo].[toSV_intComagicCalls]
AS
BEGIN

	SET NOCOUNT ON;
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
		@duration=duration,
		@utm_source=utm_source,
		@utm_medium=utm_medium,
		@utm_term=utm_term,
		@utm_content=utm_content,
		@referrer=referrer,
		@city=city
	FROM intComagicCalls WHERE sv=0 ORDER BY call_date
	IF @id IS NULL
		RETURN 0

	--Нормализация номера телефона
	SET @phoneNumber=RIGHT(@phoneNumber,10)

	--Тестовые значения
	--SET @phoneNumber='9165750202'
	--SET @id=100
	
	SELECT 
		@clientID=c.code 
	FROM 
		uchet.dbo.company c (NOLOCK) 
	WHERE 
		upcode IN (SELECT code FROM uchet.dbo.company (NOLOCK) WHERE upcode=276)
	AND LEFT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone,'.','') ,':','') ,'тел','') ,' ','') ,')','') ,'(','') ,'-',''),'+7',''),10)=@phoneNumber
	
	--Если клиент не найден, то проставляется неизвестный клиент.
	SET @clientID=ISNULL(@clientID,1501)
	
	--SELECT * FROM uchet.dbo.company WHERE code=@clientID
	
	exec uchet.dbo.InitProcess 555,0
	DECLARE @drcodes table (code int)
	DECLARE @drcode int
	
	--Если найден заказ с таким номером телефона, то вписываем информацию туда.
	SELECT @drcode=max(dr.code)
	FROM uchet.dbo.doc_ref dr 
		INNER JOIN uchet.dbo.DrfOrder dro ON dr.code=dro.upcode
		INNER JOIN uchet.dbo.company cto ON cto.code=dr.c_to
	WHERE dr.type_doc='СчМК' AND (dro.TelIncoming=@phoneNumber OR cto.code=@clientID)
	IF @drcode IS NULL
	BEGIN
		INSERT INTO uchet.dbo.doc_ref (owner, type_doc, nn, date, time, dogovor, c_from, c_to, name, serial, total)
		OUTPUT inserted.code INTO @drcodes
		SELECT
			owner	= 23,
			type_doc= 'ЛИДА',
			nn		= CAST(@id AS varchar(15)),
			date	= CAST(@call_date AS date),
			time	= DATEPART(HOUR,@call_date)*3600+DATEPART(MINUTE,@call_date)*60+DATEPART(SECOND,@call_date),
			dogovor	= 0,
			c_from	= 230,
			c_to	= @clientID,
			name	= '',
			serial	= '',
			total	= 0
		SELECT @drcode=code FROM @drcodes
	END
	
	
	
	
	UPDATE uchet.dbo.DrfOrder
		SET 
			TelephonyID=@id,
			TelIncoming=@phoneNumber,
			TelDuration=@duration,
			UtmSource=@utm_source,
			UtmMedium=@utm_medium,
			UtmTerm=@utm_term,
			UtmContent=@utm_content,
			Referrer=@referrer,
			City=@city
	WHERE 
		upcode=@drcode

	UPDATE [Integration].[dbo].[intComagicCalls]
	SET sv=1
	WHERE 
		@id=id AND @call_date = call_date

	
	DELETE FROM uchet.dbo.process WHERE code=@@SPID

END

