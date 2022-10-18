

--Заполнение таблицы фактов

CREATE PROCEDURE [dbo].[fill_IlliquidGoods_Fact]

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
		(dr.type_doc='П/Ни' or dc.oper=220)
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
	--Счмтаем висяки только по складу Алмаз 29.04.22
	AND o.company IN (299,220)
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



	TRUNCATE TABLE IlliquidGoods_fact
	;WITH
	stocks AS (
		--Склады
		SELECT code FROM uchet.dbo.company c (NOLOCK) WHERE c.upcode=242
		),
	hist AS (
	--История цен
		select spy.date, nh.code, nh.price05
		from uchet.dbo.spy (nolock)
		inner join uchet.dbo.NomHist nh (NOLOCK) ON nh.upcode=spy.id
		where spy.alias='nomencl' and spy.fields like '%Цена05%'
	),
	--Висяки
	illiquidgoods AS (SELECT tovar, quantity=SUM(quantityOst), price=round(SUM(quantityOst*price)/SUM(quantityOst),2), amount=round(SUM(quantityOst*price),2) FROM @pn WHERE date <= DATEADD(m,-3,getdate()) GROUP BY tovar HAVING SUM(quantityOst)>0),
	illiquidgoods3m AS (SELECT tovar, quantity=SUM(quantityOst), price=round(SUM(quantityOst*price)/SUM(quantityOst),2), amount=round(SUM(quantityOst*price),2) FROM @pn WHERE quantityOst>0 AND date between DATEADD(m,-6,getdate()) AND DATEADD(m,-3,getdate()) GROUP BY tovar),
	illiquidgoods6m AS (SELECT tovar, quantity=SUM(quantityOst), price=round(SUM(quantityOst*price)/SUM(quantityOst),2), amount=round(SUM(quantityOst*price),2) FROM @pn WHERE quantityOst>0 AND date between DATEADD(m,-12,getdate()) AND DATEADD(m,-6,getdate()) GROUP BY tovar),
	illiquidgoods1y AS (SELECT tovar, quantity=SUM(quantityOst), price=round(SUM(quantityOst*price)/SUM(quantityOst),2), amount=round(SUM(quantityOst*price),2) FROM @pn WHERE quantityOst>0 AND date < DATEADD(m,-12,getdate()) GROUP BY tovar),
	properties AS (
	SELECT 
		tovar=n.code,
		priceActionCurrent=ISNULL(n.price05,0),
		lastCutPriceDate=ISNULL((select MAX(date) from hist where price05>n.price05 and code=n.code),'01.01.1900')
	FROM uchet.dbo.nomencl n (NOLOCK)
	inner join illiquidgoods ig ON n.code=ig.tovar
	),
	sales AS (
	SELECT
		p.tovar,
		p.priceActionCurrent,
		--p.lastCutPriceDate,
		sales=ISNULL(sum(sf.amount),0),
		salesq=ISNULL(sum(sf.quantity),0)
	FROM properties p
	LEFT JOIN Sales_fact sf ON sf.productID=p.tovar AND sf.date>=CASE WHEN p.lastCutPriceDate='01.01.1900' THEN 99999999 ELSE datepart(YEAR,p.lastCutPriceDate)*10000 + datepart(M,p.lastCutPriceDate)*100 + datepart(D,p.lastCutPriceDate) END
	group by p.tovar, p.priceActionCurrent
	),
	costAmountCurrent AS (SELECT tovar, price=round(SUM(quantityOst*price)/SUM(quantityOst),2), amount=round(SUM(quantityOst*price),2) FROM @pn WHERE quantityOst>0 GROUP BY tovar),

	trans AS (
		SELECT
			[date]=datepart(YEAR,GETDATE())*10000 + datepart(M,GETDATE())*100 + datepart(D,GETDATE())
			,[productID]=ig.tovar
			,illiquidgoods=ISNULL(ig.quantity,0)
			--ISNULL((SELECT sum(o.quantity) FROM uchet.dbo.ostatq o (NOLOCK) WHERE n.code=o.tovar AND o.lot=0 AND o.balance=23 AND o.company IN (SELECT code FROM stocks) AND o.company NOT IN (121,108,115,467) AND o.account='22'),0)
			,costAmountCurrent=ISNULL(costAmountCurrent.price,0)
			,costAmountCurrentTotal=ISNULL(costAmountCurrent.amount,0)
			,salesFromLastDate=ISNULL(sales.sales,0)
			,illiquidgoods3m=ISNULL(illiquidgoods3m.quantity,0)
			,price3m=ISNULL(illiquidgoods3m.price,0)
			,amount3m=ISNULL(illiquidgoods3m.amount,0)
			,illiquidgoods6m=ISNULL(illiquidgoods6m.quantity,0)
			,price6m=ISNULL(illiquidgoods6m.price,0)
			,amount6m=ISNULL(illiquidgoods6m.amount,0)
			,illiquidgoods1y=ISNULL(illiquidgoods1y.quantity,0)
			,price1y=ISNULL(illiquidgoods1y.price,0)
			,amount1y=ISNULL(illiquidgoods1y.amount,0)
			,priceActionCurrent=ISNULL(sales.priceActionCurrent,0)
			,salesFromLastDateQ=ISNULL(sales.salesq,0)
		FROM 
			illiquidgoods ig
			LEFT JOIN sales
				ON sales.tovar=ig.tovar
			LEFT JOIN illiquidgoods3m
				ON ig.tovar=illiquidgoods3m.tovar
			LEFT JOIN illiquidgoods6m 
				ON ig.tovar=illiquidgoods6m.tovar
			LEFT JOIN illiquidgoods1y
				ON ig.tovar=illiquidgoods1y.tovar
			LEFT JOIN costAmountCurrent
				ON ig.tovar=costAmountCurrent.tovar
		WHERE 
			ig.quantity>0
		)
	INSERT INTO [OLAP_DATA].[dbo].IlliquidGoods_fact
           ([date]
           ,[productID]
           ,illiquidgoods
           ,costAmountCurrent
           ,costAmountCurrentTotal
           ,salesFromLastDate
		   ,illiquidgoods3m
		   ,price3m
		   ,amount3m
		   ,illiquidgoods6m
		   ,price6m
		   ,amount6m
		   ,illiquidgoods1y
		   ,price1y
		   ,amount1y
		   ,priceActionCurrent
		   ,salesFromLastDateQ
           )
	SELECT
			[date]
           ,[productID]
           ,illiquidgoods
           ,costAmountCurrent
           ,costAmountCurrentTotal
           ,salesFromLastDate
		   ,illiquidgoods3m
		   ,price3m
		   ,amount3m
		   ,illiquidgoods6m
		   ,price6m
		   ,amount6m
		   ,illiquidgoods1y
		   ,price1y
		   ,amount1y
		   ,priceActionCurrent
		   ,salesFromLastDateQ
	FROM trans