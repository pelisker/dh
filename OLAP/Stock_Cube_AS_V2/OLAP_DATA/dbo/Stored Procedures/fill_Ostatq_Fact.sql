

--Заполнение таблицы фактов

CREATE PROCEDURE [dbo].[fill_Ostatq_Fact]

AS
SET DATEFORMAT dmy;

declare @pn TABLE 
(
	tovar int,
	num int,
	date datetime,
	price money,
	invoice int,
	quantityInv int,
	quantityOst int,
	primary key(tovar, num)
)
declare @ostatq TABLE
(
	tovar int PRIMARY KEY,
	quantity int
)

	INSERT INTO @pn
	SELECT 
		dc.tovar,
		num=ROW_NUMBER() over(partition by dc.tovar ORDER BY dc.tovar, dateadd(S,ISNULL(dr.time,0) ,ISNULL(dr.date,'01.01.2015')) desc), 
		--dateadd(S,ISNULL(dr.time,0) ,ISNULL(dr.date,'01.01.2015')),
		dr.date,
		dc.price,
		dc.code,
		dc.quantity,
		0
	FROM 
		uchet.dbo.document dc (NOLOCK)
	INNER JOIN
		uchet.dbo.doc_ref dr (NOLOCK)
			ON dr.code=dc.upcode
	WHERE
		(dr.type_doc='П/Ни' or dc.oper=220 or (dr.type_doc='П/Н' and oper = 467))
		and dr.owner=23
	ORDER BY dateadd(S,ISNULL(dr.time,0) ,ISNULL(dr.date,'01.01.2015'))
	INSERT INTO @ostatq
	SELECT o.tovar, SUM(o.quantity)
	FROM 
	uchet.dbo.ostatq o
	WHERE
	o.quantity>0
	AND o.account='22'
	AND o.balance=23
	GROUP BY o.tovar

DECLARE @num int=1

WHILE EXISTS(SELECT tovar FROM @ostatq WHERE quantity>0) and @num<20
BEGIN
	UPDATE @pn SET quantityOst=CASE WHEN quantityInv>o.quantity THEN o.quantity ELSE quantityInv END
	FROM @pn r
	INNER JOIN @ostatq o ON r.tovar=o.tovar
	WHERE r.num=@num

	UPDATE @ostatq SET quantity=CASE WHEN quantityInv>o.quantity THEN 0 ELSE o.quantity-quantityInv END
	FROM @pn r
	INNER JOIN @ostatq o ON r.tovar=o.tovar
	WHERE r.num=@num

	set @num=@num+1
END



	TRUNCATE TABLE Ostatq_fact
	;WITH
	stocks AS (
		--Склады
		SELECT code FROM uchet.dbo.company c (NOLOCK) WHERE c.upcode=242 and c.code not in (116)
		),
	parcels AS (
		--Партии
		SELECT
			DISTINCT
			id=ISNULL(dr.code,-1),
			parcel=p.code
		FROM uchet.dbo.Parcel p (NOLOCK) 
		LEFT JOIN uchet.
		dbo.document dc (NOLOCK) 
			ON dc.code=p.upcode
		LEFT JOIN uchet.dbo.doc_ref dr (NOLOCK) 
			ON dc.upcode=dr.code
	),
	opl AS (
		--Оплаты для оплаченных резеров
		SELECT  link, total=sum(total)  FROM uchet.dbo.doc_ref dr (NOLOCK) WHERE owner= 23 AND (dr.type_doc LIKE 'ПКО%' or dr.type_doc='ВхПл') AND link!=0 GROUP BY link),
	resAndPay AS (
		SELECT
			[productID]=dc.tovar
			,reservWithPay=SUM(CASE WHEN ISNULL(opl.total,0)>0 THEN dc.quantity ELSE 0 END)
			,reservWithoutPay=SUM(CASE WHEN ISNULL(opl.total,0)<=0 THEN dc.quantity ELSE 0 END)
			,reservWayPay=sum(CASE WHEN ISNULL(way.ok,0)=1  THEN CASE WHEN ISNULL(opl.total,0)>0 THEN dc.quantity ELSE 0 END ELSE 0 END)
			,reservStockPay=sum(CASE WHEN ISNULL(way.ok,0)=0 THEN CASE WHEN ISNULL(opl.total,0)>0 THEN dc.quantity ELSE 0 END ELSE 0 END)

		FROM 
		uchet.dbo.document dc
		INNER JOIN uchet.dbo.doc_ref sch
			ON dc.upcode=sch.code
		LEFT JOIN opl
			ON opl.link=sch.code
		LEFT JOIN (select distinct ok=1, company from uchet.dbo.ostatq (nolock) where account in ('21') and balance=23 and quantity>0 and company !=116) way ON way.company=dc.corr
		WHERE
		dc.oper=47
		AND dc.lot=0
		AND sch.owner=23
		AND dc.corr NOT IN (116)
		AND sch.type_doc NOT IN ('СчМ7','Бнак')
		GROUP BY dc.tovar
	),
	--Висяки
	pn AS 
	--Приходы
	(SELECT o.tovar, pn.date, o.quantity, pc.price 
	FROM 
	uchet.dbo.ostatq o
	INNER JOIN
		uchet.dbo.document pc ON pc.parcel=o.parcel AND pc.tovar=o.tovar
	INNER JOIN
		uchet.dbo.doc_ref pn ON pn.code=pc.upcode
	WHERE
	o.quantity>0
	AND o.account='22'
	AND o.balance=23
	AND pn.type_doc='П/Ни'
	),
	costAmountCurrent AS (SELECT tovar, price=round(SUM(quantityOst*price)/SUM(quantityOst),2) FROM @pn WHERE quantityOst>0 GROUP BY tovar),
	trans AS (
		--Остатки
		SELECT
			[date]=datepart(YEAR,GETDATE())*10000 + datepart(M,GETDATE())*100 + datepart(D,GETDATE())
			,[productID]=n.code
			,parcelID=ISNULL(parcels.id,0)
			,stock=ISNULL(sum(st.quantity),0)
			,freeStock=0
			,stock_without_parcel=0
			,reserv=0
			,way=0
			,way_reserv=0
			,reservWithPay=0
			,reservWithoutPay=0
			,reservWayPay=0
			,reservStockPay=0
			,costAmountCurrent=0
			,priceActionCurrent=0
		FROM
			uchet.dbo.nomencl (NOLOCK) n
		INNER JOIN 
			uchet.dbo.ostatq (NOLOCK) st
				ON n.code=st.tovar AND st.balance=23 AND st.account='22' AND ISNULL(st.quantity,0)!=0 
		LEFT JOIN 
			parcels
				ON st.parcel=parcels.parcel
		WHERE ISNULL(parcels.id,0)!=0
		GROUP BY n.code, parcels.id
		UNION ALL
		--Остатки без партий
		SELECT
			[date]=datepart(YEAR,GETDATE())*10000 + datepart(M,GETDATE())*100 + datepart(D,GETDATE())
			,[productID]=n.code
			,parcelID=0
			,stock=0
			,freeStock=ISNULL((SELECT sum(o.quantity) FROM uchet.dbo.ostatq o (NOLOCK) WHERE n.code=o.tovar AND o.lot=0 AND o.balance=23 AND o.company IN (SELECT code FROM stocks) AND o.company NOT IN (121,108,115,467) AND o.account='29'),0)
			,stock_without_parcel=ISNULL((SELECT sum(o.quantity) FROM uchet.dbo.ostatq o (NOLOCK) WHERE n.code=o.tovar AND o.lot=0 AND o.balance=23 AND o.company IN (SELECT code FROM stocks) AND o.company NOT IN (121,108,115,467) AND o.account='22'),0)
			,reserv=ISNULL((SELECT sum(o.quantity) FROM uchet.dbo.ostatq o (NOLOCK) WHERE n.code=o.tovar AND o.lot=0 AND o.balance=23 AND o.company IN (SELECT code FROM stocks) AND o.company NOT IN (121,108,115,467) AND o.account='28'),0)
			,way=ISNULL((SELECT sum(o.quantity) FROM uchet.dbo.ostatq o (NOLOCK) WHERE n.code=o.tovar AND o.lot=0 AND o.balance=23 AND o.company IN (121,108,115,221,462,463,465,466) AND o.account IN ('21')),0)
			,way_reserv=ISNULL((SELECT sum(o.quantity) FROM uchet.dbo.ostatq o (NOLOCK) WHERE n.code=o.tovar AND o.lot=0 AND o.balance=23 AND o.company IN (121,108,115,221,462,463,465,466) AND o.account='28'),0)
			,reservWithPay=min(ISNULL(resAndPay.reservWithPay,0))
			,reservWithoutPay=min(ISNULL(resAndPay.reservWithoutPay,0))
			,reservWayPay=min(ISNULL(resAndPay.reservWayPay,0))
			,reservStockPay=min(ISNULL(resAndPay.reservStockPay,0))
			,costAmountCurrent=min(ISNULL(costAmountCurrent.price,0))
			,priceActionCurrent=min(n.price05)
		FROM 
			uchet.dbo.nomencl (NOLOCK) n
			LEFT JOIN resAndPay 
				ON resAndPay.productID=n.code
			LEFT JOIN costAmountCurrent
				ON n.code=costAmountCurrent.tovar
		WHERE 
		n.code IN (SELECT tovar FROM uchet.dbo.ostatq o (NOLOCK) WHERE balance=23 and ISNULL(quantity,0)>0)
		GROUP BY n.code
		)
	INSERT INTO [OLAP_DATA].[dbo].[Ostatq_fact]
           ([date]
           ,[productID]
           ,parcelID
           ,stock
           ,freeStock
           ,stock_without_parcel
           ,reserv
           ,way
           ,way_reserv
           ,reservWithPay
           ,reservWithoutPay
           ,reservWayPay
           ,reservStockPay
           ,costAmountCurrent
		   ,priceActionCurrent
           )
	SELECT
			[date]
           ,[productID]
           ,parcelID
           ,stock
           ,freeStock
           ,stock_without_parcel
           ,reserv
           ,way
           ,way_reserv
           ,reservWithPay
           ,reservWithoutPay
           ,reservWayPay
           ,reservStockPay
           ,costAmountCurrent
		   ,priceActionCurrent
	FROM trans