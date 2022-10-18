

--Заполнение оборачиваемости остатков
CREATE procedure [dbo].[fill_Turnover_fact] 

as 


DELETE FROM dbo.Turnover_fact

--INSERT INTO dbo.Turnover_fact            
--			([date]
--           ,[tovar]
--           ,[lot]
--           ,[type]
--           ,[cost]
--           ,[quantity]
--           ,[ost1year]
--           ,[ost6month]
--           ,[ost3month]
--           ,[ost1month]
--           ,[sale1year]
--           ,[sale6month]
--           ,[sale3month]
--           ,[sale1month])
--SELECT
--	CONVERT(varchar(10),date,112),tovar,lot, 0, cost=case when SUM(quantity)=0 then 0 else sum(cost*quantity) end, sum(quantity), 0,0,0,0,0,0,0,0
--	FROM tmp.Ostatq_hist_fact (nolock)
--group by date, tovar, lot

--Остаток на конец месяца + среднемесячный остаток
;WITH 
salesmonth AS (
	SELECT date=dateadd(day, -1,dateadd(MONTH,(date/100)%100, dateadd(year,(date/10000)%100,'01.01.00')))
	, tovar=ProductID
	, amount=SUM(amount)
	, costamount=sum(costamount)
	from Sales_fact (NOLOCK)
	group by (date/10000)%100, (date/100)%100, productID
	)
,ostendmonth AS (
	SELECT
	   [date]=dateadd(day, -1, dateadd(month, 1, dateadd(day,-day(max(date)) + 1, max(date)))) --Последний день месяца
	   ,oneyear=datepart(year,date)
	   ,sixmonth=1+(datepart(MONTH,date)-1)/6
	   ,threemonth=1+(datepart(MONTH,date)-1)/3
	   ,[tovar]
	   ,[lot]=0
	   ,[type]=1
	   --Остатки на последний день каждого месяца.
	   ,[cost]=sum(case when date=dateadd(day, -1, dateadd(month, 1, dateadd(day,-day(date) + 1, date))) then cost*quantity else 0 end)
	   ,[quantity]=sum(case when date=dateadd(day, -1, dateadd(month, 1, dateadd(day,-day(date) + 1, date))) then quantity else 0 end)
	   ,[ost1year]=0
	   ,[ost6month]=0
	   ,[ost3month]=0
		--Средний остаток за месяц( Остаток 1/2(первый и последний день месяца)+сумма остальных дней / (дней месяца-1) )
	   ,[ost1month]=SUM(
	   case 
		when 
		datepart(day,date) IN (1,day(dateadd(day, -1, dateadd(month, 1, dateadd(day,-day(date) + 1, date))))) 
		then cost*quantity/2 else cost*quantity end
	   )/(day(dateadd(day, -1, dateadd(month, 1, dateadd(day,-day(max(date)) + 1, max(date)))))-1)
	   ,[sale1year]=0
	   ,[sale6month]=0
	   ,[sale3month]=0
	   ,[sale1month]=0--продажи за каждый месяц
	FROM tmp.Ostatq_hist_fact (nolock)
	group by datepart(year,date), datepart(month,date), tovar--, lot
	)
, statmonth AS (
	select  
		[date]=om.date
		,oneyear
		,threemonth
		,sixmonth
	   ,[tovar]=om.tovar
	   ,[lot]
	   ,[type]
	   ,[cost]
	   ,[quantity]
	   ,[ost1year]
	   ,[ost6month]
	   ,[ost3month]
	   ,[ost1month]
	   ,[sale1year]
	   ,[sale6month]
	   ,[sale3month]
	   ,[sale1month]=ISNULL(sm.amount,0)
	from ostendmonth om
	left join salesmonth sm ON om.date=sm.date and om.tovar=sm.tovar
	)

INSERT INTO dbo.Turnover_fact            
			([date]
           ,[tovar]
           ,[lot]
           ,[type]
           ,[cost]
           ,[quantity]
           ,[ost1year]
           ,[ost6month]
           ,[ost3month]
           ,[ost1month]
           ,[sale1year]
           ,[sale6month]
           ,[sale3month]
           ,[sale1month])

--Год
--Средний месячный остаток за год
SELECT
   [date]=CONVERT(varchar(10),cast(oneyear AS varchar(4))+'1231',112)
   ,[tovar]
   ,[lot]
   ,[type]=4
   ,[cost]=0
   ,[quantity]=0
   ,[ost1year]=SUM(case when datepart(month,date) in (1,12) then cost/2 else cost end)/11
   ,[ost6month]=0
   ,[ost3month]=0
   ,[ost1month]=0
   ,[sale1year]=SUM(sale1month)
   ,[sale6month]=0
   ,[sale3month]=0
   ,[sale1month]=0
FROM statmonth
group by oneyear, tovar, lot

union all
--Полгода
--Средний месячный остаток за полгода
SELECT
   [date]=CONVERT(varchar(10),cast(oneyear AS varchar(4))+case when sixmonth=1 then '0630' else '1231' end,112)
   ,[tovar]
   ,[lot]
   ,[type]=3
   ,[cost]=0
   ,[quantity]=0
   ,[ost1year]=0
   ,[ost6month]=SUM(case when datepart(month,date) in (1,6,7,12) then cost/2 else cost end)/5
   ,[ost3month]=0
   ,[ost1month]=0
   ,[sale1year]=0
   ,[sale6month]=SUM(sale1month)
   ,[sale3month]=0
   ,[sale1month]=0
FROM statmonth
group by oneyear, sixmonth, tovar, lot

union all
--Квартал
--Средний месячный остаток за три месяца
SELECT
   [date]=CONVERT(varchar(10),cast(oneyear AS varchar(4))+case threemonth when 1 then '0331' when 2 then '0630' when 3 then '0930' else '1231' end,112)
   ,[tovar]
   ,[lot]
   ,[type]=2
   ,[cost]=0
   ,[quantity]=0
   ,[ost1year]=0
   ,[ost6month]=0
   ,[ost3month]=SUM(case when datepart(month,date) in (1,3,4,6,7,9,10,12) then cost/2 else cost end)/2
   ,[ost1month]=0
   ,[sale1year]=0
   ,[sale6month]=0
   ,[sale3month]=SUM(sale1month)
   ,[sale1month]=0
FROM statmonth
group by oneyear, threemonth, tovar, lot


union all 
select  
	[date]=CONVERT(varchar(10),date,112)
   ,[tovar]
   ,[lot]
   ,[type]=1
   ,[cost]
   ,[quantity]
   ,[ost1year]
   ,[ost6month]
   ,[ost3month]
   ,[ost1month]
   ,[sale1year]
   ,[sale6month]
   ,[sale3month]
   ,[sale1month]
from statmonth 
order by [type], date, tovar