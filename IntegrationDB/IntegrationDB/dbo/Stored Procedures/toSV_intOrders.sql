
-- =============================================
-- Author:		SCH
-- Create date: 10.03.2016
-- Description:	Загрузка лидов(заказов) с сайта
-- =============================================
CREATE PROCEDURE [dbo].[toSV_intOrders]

AS

BEGIN

	SET NOCOUNT ON;
	DECLARE @id int
	,@phoneNumber varchar(20)
	,@phoneNumber2 varchar(20)
	,@email varchar(50)
	,@email2 varchar(50)
	,@clientName varchar(200)
	,@clientID int
	,@intClient int
	,@date datetime
	,@ac_id int
	,@deliverycost money
	,@payment varchar(max)
	,@delivery varchar(200)
	,@utm_source varchar(500)
	,@utm_medium varchar(500)
	,@utm_term varchar(500)
	,@utm_content varchar(2000)
	,@utm_compaign varchar(2000)
	,@referrer varchar(2000)
	,@city varchar(50)

	DECLARE @codes table (code int)

	SELECT top 1 
		@id=ref.code, 
		@phoneNumber=ref.phonenumber,
		@email=ref.email,
		@date = ref.date,
		@deliverycost= ref.deliverycost,
		@payment = ref.payment,
		@delivery = ref.delivery,
		@intClient=ref.client,
		@utm_source=ref.utm_source,
		@utm_medium=ref.utm_medium,
		@utm_term=ref.utm_term,
		@utm_content=ref.utm_content,
		@utm_compaign=ref.utm_campaign,
		@referrer=referrer,
		@city=ref.city
	FROM intOrderRef ref
	INNER JOIN intClient cl ON ref.client=cl.code
	WHERE ref.sv=0 ORDER BY date
	IF @id IS NULL
		RETURN 0

	SELECT
		@clientName=c.name,
		@phoneNumber2=c.phone,
		@email2=c.email
	FROM
		intClient c
	WHERE c.code=@intClient

	--Нормализация номера телефона
	SET @phoneNumber=LEFT(REPLACE(REPLACE(REPLACE(REPLACE(@phoneNumber,'(','') ,')','') ,'-','') ,' ',''),10)
	SET @phoneNumber2=LEFT(REPLACE(REPLACE(REPLACE(REPLACE(@phoneNumber2,'(','') ,')','') ,'-','') ,' ',''),10)
	--Тестовые значения
	--SET @phoneNumber='9165750202'
	--SET @id=100
	
	SELECT 
		@clientID=c.code 
	FROM 
		uchet.dbo.company c (NOLOCK) 
		INNER JOIN uchet.dbo.comparam cmp (NOLOCK) 
			ON c.code=cmp.upcode
	WHERE 
		cmp.intCode=@intClient
		
	--Если клиент не найден по ID, то ищется по номеру телефона.		
	IF @clientID IS NULL
	BEGIN
		SELECT 
			@clientID=c.code 
		FROM 
			uchet.dbo.company c (NOLOCK) 
			LEFT JOIN uchet.dbo.comparam cmp (NOLOCK) 
				ON c.code=cmp.upcode
		WHERE
			--c.upcode IN (SELECT code FROM uchet.dbo.company (NOLOCK) WHERE upcode=276) AND 
			(LEFT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone,'.','') ,':','') ,'тел','') ,' ','') ,')','') ,'(','') ,'-',''),'+7',''),10)=@phoneNumber AND c.phone!='')
			OR 
			(LEFT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone,'.','') ,':','') ,'тел','') ,' ','') ,')','') ,'(','') ,'-',''),'+7',''),10)=@phoneNumber2 AND c.phone!='')
			OR
			
			(LEFT(REPLACE(REPLACE(cmp.persPhone ,')','') ,'(',''),10)=@phoneNumber AND cmp.persPhone!='')
			OR
			(LEFT(REPLACE(REPLACE(cmp.persPhone ,')','') ,'(',''),10)=@phoneNumber2 AND cmp.persPhone!='')
			OR
			(c.email=@email AND c.email!='')
			OR
			(c.email=@email2 AND c.email!='')
			OR
			(cmp.persEmail=@email AND cmp.persEmail!='')
			OR
			(cmp.persEmail=@email2 AND cmp.persEmail!='')
		--Если клиент найден по телефону, то привязывается к клиенту в справочнике.
		IF @clientID IS NOT NULL
		BEGIN
			UPDATE uchet.dbo.comparam SET intCode=@intClient WHERE upcode=@clientID
			IF @@ROWCOUNT=0
				INSERT INTO uchet.dbo.comparam (upcode,intCode) VALUES (@clientID,@intClient)
			UPDATE [Integration].[dbo].intClient
				SET sv=1
			WHERE 
				code=@intClient
		END
	END
	
	--Если клиент не найден, то проставляется неизвестный покупатель.
	SET @clientID=ISNULL(@clientID,1502)			
	--IF @clientID IS NULL
	--BEGIN
	--	INSERT INTO uchet.dbo.company (upcode,name,company,phone)
	--	OUTPUT inserted.code INTO @codes
	--	SELECT 
	--		upcode=311, 
	--		name='Клиент № '+CAST(@intClient AS varchar)+' '+LTRIM(RTRIM(c.name)),
	--		company=c.name,
	--		phone=LEFT(REPLACE(REPLACE(REPLACE(REPLACE(c.phone,'(','') ,')','') ,'-','') ,' ',''),10)
	--	FROM intClient c
	--	WHERE c.code=@intClient
	--	SET @clientID=(SELECT max(code) FROM @codes)
	--	UPDATE uchet.dbo.comparam SET intCode=@intClient WHERE upcode=@clientID
	--	IF @@ROWCOUNT=0
	--		INSERT INTO uchet.dbo.comparam (upcode,intCode) VALUES (@clientID,@intClient)
	--	DELETE FROM @codes
	--	UPDATE [Integration].[dbo].intClient
	--		SET sv=1
	--	WHERE 
	--		code=@intClient
	--END
	
	exec uchet.dbo.InitProcess 555,0
	
	DECLARE @drcode int

	--Если такого заказа еще нет, то создаем, иначе обновляем существующий.
	SELECT @drcode=max(dr.code)
	FROM uchet.dbo.doc_ref dr (NOLOCK)
		INNER JOIN uchet.dbo.DrfOrder dro (NOLOCK) ON dr.code=dro.upcode
	WHERE dr.type_doc IN ('ЛИД') AND dro.IntID=@id
	IF @drcode IS NULL
	BEGIN
		INSERT INTO uchet.dbo.doc_ref (owner, type_doc, nn, date, time, dogovor, c_from, c_to, name, serial, total)
		OUTPUT inserted.code INTO @codes
		SELECT
			owner	= 23,
			type_doc= 'ЛИД',
			nn		= CAST(@id AS varchar(15)),
			date	= CAST(@date AS date),
			time	= DATEPART(HOUR,@date)*3600+DATEPART(MINUTE,@date)*60+DATEPART(SECOND,@date),
			dogovor	= 0,
			c_from	= CASE WHEN @city='Москва' OR @payment LIKE '%Chronopay%' THEN 226 ELSE 229 END,
			c_to	= @clientID,
			name	= CASE @intClient WHEN 1502 THEN @clientName ELSE '' END + ' ' + ltrim(rtrim(@payment)),
			serial	= CAST(@id AS varchar(15)),
			total	= 0
		SELECT @drcode=code FROM @codes
	END
	ELSE
		DELETE FROM uchet.dbo.document WHERE upcode=@drcode
	
	--Вставка строк с товарами
	;WITH det AS 
		(SELECT 
			tovar,
			price,
			comment, 
			quantity=SUM(quantity)
		FROM intOrderDet (NOLOCK)
		WHERE
			upcode=@id 
		GROUP BY tovar,price,comment)
	INSERT INTO uchet.dbo.document (upcode,oper,tovar,quantity,edizm,price,amount,valuta,corr,note)
	SELECT 
		upcode=@drcode,
		oper=47,
		tovar=det.tovar,
		quantity=so.quantity,
		edizm='шт.',
		price=det.price,
		amount=so.quantity*det.price,
		valuta='руб.',
		corr=so.company,
		note=det.comment
	FROM
		det
		CROSS APPLY (SELECT * FROM uchet.dbo.ad_getSOTovar(det.tovar,0,det.quantity,23)) AS so
		
	--SELECT 
	--	upcode=@drcode,
	--	oper=47,
	--	tovar=det.tovar,
	--	quantity=det.quantity,
	--	edizm='шт.',
	--	price=det.price,
	--	amount=det.quantity*det.price,
	--	valuta='руб.',
	--	corr=116,
	--	note=det.comment
	--FROM
	--	intOrderDet det (NOLOCK)
	--WHERE
	--	det.upcode=@id
	
	--Добавление доставки
	IF ISNULL(@deliverycost,0)!=0
		INSERT INTO uchet.dbo.document (upcode,oper,tovar,quantity,edizm,price,amount,valuta,corr,note)
		SELECT 
		upcode=@drcode,
		oper=405,
		tovar=6653,
		quantity=1,
		edizm='шт.',
		price=@deliverycost,
		amount=@deliverycost,
		valuta='руб.',
		corr=0,
		note=@delivery
	
	--Обновление суммы заказа
	UPDATE uchet.dbo.doc_ref SET total=(SELECT SUM(amount) FROM uchet.dbo.document (NOLOCK) WHERE upcode=@drcode) WHERE code=@drcode
	
	--Обновление данных заказа
	UPDATE uchet.dbo.DrfOrder
	SET
		intID=@id,
		TelIncoming=@phoneNumber,
		UtmSource=@utm_source,
		UtmMedium=@utm_medium,
		UtmTerm=@utm_term,
		UtmContent=@utm_content,
		utm_campaign=@utm_compaign,
		Referrer=@referrer,
		City=@city
	WHERE 
		upcode=@drcode

	UPDATE [Integration].[dbo].intOrderRef
	SET sv=1
	WHERE 
		code=@id
	UPDATE [Integration].[dbo].intOrderDet
	SET sv=1
	WHERE 
		upcode=@id

	DELETE FROM uchet.dbo.process WHERE code=@@SPID

	--DECLARE @date datetime,
	--		@BonusDate date,
	--		@Nomer VARCHAR(32), 
	--		@Author VARCHAR(50), 
	--		@summa money,
	--		@TovID int,
	--		@price money,
	--		@price_delivery money,
	--		@cost_delivery money,
	--		@TovCode int,
	--		@Vid VARCHAR(32), 
	--		@DestinationID VARCHAR(32), 
	--		@Direction int,
	--		@NewCode int,
	--		@link int,
	--		@store int,
	--		@Nomer2 VARCHAR(32), 
	--		@Data DATETIME, 
	--		@Status INT, 
	--		@re VARCHAR(512),
	--		@c_to int,
	--		@c_from int,
	--		@c_thro int,
	--		@client int,
	--		@clientBLK int,
	--		@contractor int,
	--		@dogovor int,
	--		@name varchar(200)='',
	--		@note varchar(200),
	--		@oper int,
	--		@error_message varchar(1000)

	--SELECT top 1
	--	@date = rp.date,
	--	@BonusDate = rp.zakdate,
	--	@Nomer=Nomer,
	--	@Author=Author,
	--	@dogovor=dg.code,
	--	@TovID=TovID,
	--	@summa=Summa,
	--	@price=ISNULL(Summa,0)+ISNULL(DostSEB,0)-ISNULL(DostPrice,0),
	--	@price_delivery=ISNULL(DostPrice,0),
	--	@cost_delivery=ISNULL(DostSEB,0),
	--	@TovCode=svcode,
	--	@store=c.code
	--FROM 
	--	[Integration].[dbo].intOrderRef  rp
	--	LEFT JOIN dogovor dg
	--		ON dg.name=rp.Author COLLATE SQL_Latin1_General_CP1251_CI_AS 
	--	LEFT JOIN doc_ref dr (NOLOCK)
	--		ON dr.code=rp.DestinationID AND dr.date=rp.date AND dr.type_doc='ЧЕК+'
	--	LEFT JOIN company c (NOLOCK)
	--		ON c.dop_info=rp.magazin COLLATE SQL_Latin1_General_CP1251_CI_AS
	--	LEFT JOIN cllc_vend_stock_links vsl (NOLOCK)
	--		ON vsl.upcode=99 AND vsl.id=CAST(TovID AS varchar(10))
	--WHERE
	--	dr.code IS NULL 
	--	--Временно
	--	AND dg.code IS NOT NULL
	--	--AND rp.Summa>=0
	--ORDER BY rp.date
		
	--IF @@ROWCOUNT=0
	--BEGIN
	--	print 'Нет чеков для загрузки.'
	--	RETURN 0
	--END
	--SET @client=448
	--SET @store=ISNULL(@store,99)
	--SET @link=0
	
	--------------------
	-------Проверки-----
	--------------------
	--IF ISNULL(@TovCode,0)=0
	--BEGIN
	--	SET @error_message='Не связан товар!!! ID билкона: '+CAST(ISNULL(@TovID,0) AS varchar(10))
	--	RAISERROR(@error_message,16,10) WITH SETERROR
	--	RETURN
	--END



	--	--Поиск связанной продажи. Если есть, значит это обмен. Если нет, то просто не заведен менеджер.
	--	SELECT top 1
	--		@link	= ISNULL(dr.code,0),
	--		@dogovor= dr.dogovor,
	--		@store	= dr.c_from,
	--		@name='Обмен. Загружено из 1С'
	--	FROM 
	--		--OPENQUERY([PARTNER],'SELECT * FROM [Integration].[dbo].[Roznitsa] WHERE direction=0 AND DestinationID IS NOT NULL AND Summa>0') rp
	--		--Заказ, к которому привязана продажа.
	--		doc_ref dr (NOLOCK)
	--		--	ON dr.nn=rp.nomer COLLATE SQL_Latin1_General_CP1251_CI_AS AND dr.type_doc='ЧЕК+'
	--		--LEFT JOIN cllc_vend_stock_links vsl (NOLOCK)
	--		--	ON vsl.upcode=99 AND vsl.id=CAST(TovID AS varchar(10))
	--	WHERE
	--		dr.nn=@Nomer AND name like 'Продажа.%'
	--	ORDER BY dr.date DESC	
	--	--Обмен
		
	--	IF ISNULL(@dogovor,0)=0
	--	BEGIN
	--		RAISERROR('Не найден менеджер в справочнике договоров. (dogovor)!!!',16,10) WITH SETERROR
	--		RETURN
	--	END
	--END


	
	--IF @price>=0
	--BEGIN
	---------------------
	--------Продажа------
	---------------------
	
	--	SELECT
	--		@c_from=@store,
	--		@c_to=@client,
	--		@c_thro=0,
	--		@oper=313,
	--		@dogovor=ISNULL(@dogovor,0),
	--		@note='',
	--		@name=CASE WHEN @name='' THEN 'Продажа. Загружено из 1С' ELSE @name END

	--	----------------------
	--	-----Втавка шапки-----
	--	----------------------
	--	INSERT INTO doc_ref (date,nn,owner,type_doc,c_from,c_to,c_thro,dogovor,name,note,serial,total,valuta,link)
	--	SELECT 
	--		[date]		= @date,
	--		nn			= @Nomer,
	--		owner		= 1,
	--		type_doc	= 'ЧЕК+',
	--		c_from		= @c_from,
	--		c_to		= @c_to,
	--		c_thro		= @c_thro,
	--		dogovor		= @dogovor,
	--		name		= @name,
	--		note		= @note,
	--		serial		= '1354',
	--		total		= @price,
	--		valuta		= 'руб.',
	--		link		= ISNULL(@link,0)
		
	--	SELECT @NewCode = SCOPE_IDENTITY()
		
	--	print @Name
	--	print @NewCode

	--	IF ISNULL(@NewCode,0)=0
	--	BEGIN
	--		RAISERROR('Ошибка создания документа!!!',16,10) WITH SETERROR
	--		RETURN
	--	END
		
	--	INSERT INTO document (upcode, oper, tovar, lot, edizm, quantity, quantity2, quantity3
	--					, price, valuta, amount, note, memo, corr)
	--	--Товар
	--	SELECT
	--		upcode      = @NewCode
	--		, oper      = @oper
	--		, tovar     = @TovCode
	--		, lot       = 0
	--		, edizm     = 'шт.'
	--		, quantity  = 1
	--		, quantity2 = 0
	--		, quantity3 = 0
	--		, price     = @price
	--		, valuta    = 'руб.'
	--		, amount    = @price
	--		, note      = ''
	--		, memo      = ''
	--		, corr      = 99
	--	UNION ALL
	--	--Доставка
	--	SELECT
	--		upcode      = @NewCode
	--		, oper      = 581
	--		, tovar     = 57
	--		, lot       = 0
	--		, edizm     = 'шт.'
	--		, quantity  = 1
	--		, quantity2 = 0
	--		, quantity3 = @cost_delivery
	--		, price     = @price_delivery
	--		, valuta    = 'руб.'
	--		, amount    = @price_delivery
	--		, note      = ''
	--		, memo      = ''
	--		, corr      = 1
		
	--	UPDATE DrfParam SET createdate=@BonusDate WHERE upcode=@NewCode

	--	UPDATE OPENQUERY([PARTNER],'SELECT * FROM [Integration].[dbo].[Roznitsa] WHERE direction=1')
	--	SET direction=0, DestinationID=@NewCode WHERE nomer=@Nomer AND date=@date AND Author=@Author AND TovID=@TovID AND summa=@Summa
	--	--Расчет бонуса
	--	exec cllc_RecalcDrBonus @NewCode,NULL,NULL
	--END
	--ELSE
	--BEGIN
	---------------------
	--------Возврат------
	---------------------
	--	--Поиск продажи по которой был возврат.
	--	SELECT top 1
	--		@link	= ISNULL(dr.code,0)
	--	FROM 
	--		doc_ref dr (NOLOCK)
	--	WHERE
	--		dr.nn=@Nomer AND name like 'Продажа.%'
	--	ORDER BY dr.date DESC	
		
	--	IF ISNULL(@dogovor,0)=0
	--	BEGIN
	--		RAISERROR('Не найдена продажа для возврата!!!',16,10) WITH SETERROR
	--		RETURN
	--	END
	
	--	SELECT
	--		@c_from=@client,
	--		@c_to=@store,
	--		@c_thro=0,
	--		@oper=171,
	--		@dogovor=ISNULL(@dogovor,0),
	--		@note='',
	--		@name='Возврат. Загружено из 1С'

	--	----------------------
	--	-----Втавка шапки-----
	--	----------------------
	--	INSERT INTO doc_ref (date,nn,owner,type_doc,c_from,c_to,c_thro,dogovor,name,note,serial,total,valuta,link)
	--	SELECT 
	--		[date]		= @date,
	--		nn			= @Nomer,
	--		owner		= 1,
	--		type_doc	= 'ВЗВр',
	--		c_from		= @c_from,
	--		c_to		= @c_to,
	--		c_thro		= @c_thro,
	--		dogovor		= @dogovor,
	--		name		= @name,
	--		note		= @note,
	--		serial		= '1354',
	--		total		= @price,
	--		valuta		= 'руб.',
	--		link		= ISNULL(@link,0)
		
	--	SELECT @NewCode = SCOPE_IDENTITY()
		
	--	print @Name
	--	print @NewCode
		
	--	IF ISNULL(@NewCode,0)=0
	--	BEGIN
	--		RAISERROR('Ошибка создания документа!!!',16,10) WITH SETERROR
	--		RETURN
	--	END
		
	--	INSERT INTO document (upcode, oper, tovar, lot, edizm, quantity, quantity2, quantity3
	--					, price, valuta, amount, note, memo, corr)
	--	SELECT
	--		upcode      = @NewCode
	--		, oper      = @oper
	--		, tovar     = @TovCode
	--		, lot       = 0
	--		, edizm     = 'шт.'
	--		, quantity  = -1
	--		, quantity2 = 0
	--		, quantity3 = 0
	--		, price     = -@price
	--		, valuta    = 'руб.'
	--		, amount    = @price
	--		, note      = ''
	--		, memo      = ''
	--		, corr      = 0
		
	--	UPDATE DrfParam SET createdate=@BonusDate WHERE upcode=@NewCode

	--	UPDATE OPENQUERY([PARTNER],'SELECT * FROM [Integration].[dbo].[Roznitsa] WHERE direction=1')
	--	SET direction=0, DestinationID=@NewCode WHERE nomer=@Nomer AND date=@date AND Author=@Author AND TovID=@TovID AND summa=@Summa
	--	--Расчет бонуса
	--	exec cllc_RecalcDrBonus @NewCode,NULL,NULL

	
	--END

END

