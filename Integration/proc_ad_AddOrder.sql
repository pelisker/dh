GO
/****** Object:  StoredProcedure [dbo].[toSV_intOrders]    Script Date: 08/26/2016 14:57:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		SCH
-- Create date: 26.08.2016
-- Description:	Проедура создания заказа
-- =============================================
CREATE PROCEDURE [dbo].[ad_AddOrder]
(	
	@id int
	,@idInt int
	,@idPhone int
	,@date datetime
	,@clientIDamo int
	,@Manager varchar(100)
	,@tovars varchar(max)
	,@DeliveryDate datetime
	,@DeliveryFIO varchar(500)
	,@DeliveryPhone1 varchar(20)
	,@DeliveryPhone2 varchar(20)
	,@DeliveryCost money
	,@DeliveryComment varchar(200)
	,@DeliveryCity varchar(50)
	,@DeliveryAddress varchar(500)
	,@utm_source varchar(500)
	,@utm_medium varchar(500)
	,@utm_term varchar(500)
	,@utm_content varchar(2000)
	,@utm_compaign varchar(2000)
	,@referrer varchar(2000)
)

AS

BEGIN
	SET NOCOUNT ON;

	DECLARE @codes table (code int)

	IF @id IS NULL
		RETURN -1

	DECLARE @clientID int, @managerID int, @c_from int, @nn varchar(20), @city int
	
	--Поиск клиента
	SELECT
		@clientID=c.code
	FROM
		company c (NOLOCK)
	INNER JOIN
		comparam cmp (NOLOCK)
			ON c.code=cmp.upcode
	WHERE 
		/*Новое поле*/
		cmp.intCode=@clientIDamo

	--Если клиент не найден, то проставляется неизвестный покупатель.
	--IF @clientid IS NULL
	--	RETURN -1
	SET @clientID=ISNULL(@clientID,1502)			

	--Поиск менеджера
	SET @managerID=ISNULL((SELECT code FROM dogovor (NOLOCK) WHERE name=@Manager),0)
	
	--Определение откого
	SET @c_from=229
	
	--Определение номера
	SET @nn='1'
	
	exec uchet.dbo.InitProcess 555,0
	
	DECLARE @drcode int

	--Если такого заказа еще нет, то создаем, иначе обновляем существующий.
	SELECT @drcode=max(dr.code)
	FROM uchet.dbo.doc_ref dr (NOLOCK)
		INNER JOIN uchet.dbo.DrfOrder dro (NOLOCK) ON dr.code=dro.upcode
	/*Новое поле*/
	WHERE dr.type_doc IN ('СчМК') AND dro.IntID=@id
	IF @drcode IS NULL
	BEGIN
		INSERT INTO uchet.dbo.doc_ref (owner, type_doc, nn, date, time, dogovor, c_from, c_to, name, serial, total)
		OUTPUT inserted.code INTO @codes
		SELECT
			owner	= 23,
			type_doc= 'СчМК',
			nn		= @nn,
			date	= CAST(@date AS date),
			date2	= ISNULL(@DeliveryDate,CAST(@date AS date)),
			time	= DATEPART(HOUR,@date)*3600+DATEPART(MINUTE,@date)*60+DATEPART(SECOND,@date),
			dogovor	= @managerID,
			c_from	= @c_from,
			c_to	= @clientID,
			name	= '',
			serial	= '',
			total	= 0
		SELECT @drcode=code FROM @codes
	END
	--ELSE
	--	DELETE FROM uchet.dbo.document WHERE upcode=@drcode
	
	--Вставка строк с товарами
	;WITH det AS 
		(SELECT 
			tovar=left(txt,CHARINDEX(':',txt)-1),
			quantity=RIGHT(txt,len(txt)-CHARINDEX(':',txt))
		FROM SplitInTableD(@tovars,';')
		)
	INSERT INTO uchet.dbo.document (upcode,oper,tovar,quantity,edizm,price,amount,valuta,corr,note)
	SELECT 
		upcode=0,
		oper=47,
		tovar=det.tovar,
		quantity=so.quantity,
		edizm='шт.',
		price=n.price04,
		amount=so.quantity*n.price04,
		valuta='руб.',
		corr=so.company,
		note=''
	FROM
		det
		INNER JOIN 
			nomencl n (NOLOCK)
				ON n.code=det.tovar
		CROSS APPLY (SELECT * FROM uchet.dbo.ad_getSOTovar(det.tovar,0,det.quantity,23)) AS so

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
		note=''
	
	--Обновление суммы заказа
	UPDATE uchet.dbo.doc_ref SET total=(SELECT SUM(amount) FROM uchet.dbo.document (NOLOCK) WHERE upcode=@drcode) WHERE code=@drcode
	
	--Обновление данных заказа
	UPDATE uchet.dbo.DrfOrder
	SET
		amoID=@id,
		intID=@idInt,
		UtmSource=@utm_source,
		UtmMedium=@utm_medium,
		UtmTerm=@utm_term,
		UtmContent=@utm_content,
		utm_campaign=@utm_compaign,
		Referrer=@referrer,
	WHERE 
		upcode=@drcode


	--Обновление данных доставки
	UPDATE uchet.dbo.DrfDelivery
	SET
		ai_name=@DeliveryFIO
		,ai_phone1=@DeliveryPhone1
		,ai_phone2=@DeliveryPhone2
		,ai_comment=@DeliveryComment
		,ai_city=@City
		,ai_street=@DeliveryAddress
	WHERE 
		upcode=@drcode

	DELETE FROM uchet.dbo.process WHERE code=@@SPID

END

