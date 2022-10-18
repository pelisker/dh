



CREATE VIEW [bi].[SpeedOfSales]
AS


with Sales AS (
	select
		date=CASE WHEN dateOfPay<date THEN dateOfPay ELSE date END 
		,s.productID
		,quantity=SUM(quantity)
	from
		Sales_fact s (NOLOCK)
	where
		dateOfPay > cast(convert(varchar(10),GETDATE()-365,112) AS int)
	group by date, dateOfPay
	, s.productID
	)
	, ostat AS (
	select
		date, tovar, quantity=SUM(quantity)
	from
		[OLAP_DATA].[tmp].[OstatqHistWithoutCompany_fact] (nolock)
	where account='22' and date>GETDATE()-365 and lot=0 and quantity>0
	group by date, tovar
	)

SELECT 
	date=t.year*10000+t.monthNum*100+1, tovar, stockDay=isnull(COUNT(distinct o.date),0), salesOfMonth=ISNULL(sum(s.quantity),0), daysOfMonth=COUNT(distinct t.date)
FROM
	times_dim t 
	LEFT JOIN 
	ostat o
		ON t.date=o.date
	LEFT JOIN 
	sales s
		ON 
		o.tovar=s.productID AND
		t.date=convert(date, right(CAST(s.date AS varchar(8)),2)+'.'+right(left(CAST(s.date AS varchar(8)),6),2)+'.'+left(CAST(s.date AS varchar(8)),4),104)
WHERE
t.date>GETDATE()-365 and o.quantity>0
GROUP BY t.year, t.monthNum, o.tovar


--SELECT 

--	t.year, t.monthNum, tovar, lot, o.date, COUNT(o.quantity)

--FROM 
--	times_dim t INNER JOIN 
--	[OLAP_DATA].[tmp].[OstatqHistWithoutCompany_fact] (nolock) o
--	ON t.date=o.date

--WHERE 
--tovar=54119
--and account='22' 
--and t.date>GETDATE()-125 and o.quantity>0
--GROUP BY t.year, t.monthNum, tovar, lot, o.date



--Нужны
--Количество дней с остатком в месяц.