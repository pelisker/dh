
--Расчет истории остатков по проводкам, 22 счет
CREATE procedure [tmp].[fill_Ostatq_Hist_fact] 
(@start datetime, @end datetime, @tov int)

as 


declare  
	--@start datetime
	--,@end datetime
	@current datetime
	--,@tov int

IF OBJECT_ID('tempdb..#dayLog') IS NOT NULL 
	DROP TABLE #dayLog;

--Заполнение дат
IF OBJECT_ID('tempdb..#days') IS NOT NULL 
	DROP TABLE #days;

--set @start = '20190101'
--set @end = '20201007' --GETDATE()-2000
set @current = @start


IF OBJECT_ID('tempdb..#log') IS NOT NULL 
DROP TABLE #log;


with 
--Список перемещений
per AS (
	--Это были перемещения со списаниями и оприходованиями в одном документе но не в одной проводке, но там приход не по учетной себестоимости
	--select distinct dc.upcode from 
	--document dc 
	--inner join opert t on dc.oper=t.code
	--inner join oper o on t.code=o.upcode
	--where o.accd='22' or o.acck='22'
	--group by dc.upcode
	--having sum(case when o.accd='22' then 1 else 0 end)>1 and sum(case when o.acck='22' then 1 else 0 end)>1
	
	select distinct t.code
	from uchet.dbo.opert t
	inner join uchet.dbo.oper o on t.code=o.upcode
	where o.accd='22' or o.acck='22'
	group by t.code
	having sum(case when o.accd='22' then 1 else 0 end)>=1 and sum(case when o.acck='22' then 1 else 0 end)>=1
)
,logdc AS  (
	SELECT oper=0
	, dc.code*10+1 as code
	, dr.code as drcode
	, dr.date
	, dr.time
	, case when per.code is not null then 1 else 0 end AS per
	, account.code as account
	, (CASE oper.ComDeb WHEN 1 THEN dr.c_from WHEN 2 THEN dr.c_to WHEN 3 THEN dr.c_thro WHEN 4 THEN oper.ComDVal WHEN 5 THEN dc.corr ELSE dr.c_to END) as company
	, dc.tovar
	, (CASE WHEN n.en_subcode = 1 THEN dc.lot ELSE 0 END) as lot
	, dc.parcel
	, case when sum(dc.quantity)=0 then 0 else sum(dc.amount)/sum(dc.quantity) end as cost
	, sum(dc.quantity) as quantity
	from uchet.dbo.doc_ref dr (nolock) 
	INNER JOIN uchet.dbo.document dc (nolock) on dr.code=dc.upcode
	INNER JOIN uchet.dbo.nomencl n (NOLOCK) ON dc.tovar=n.code
	INNER JOIN uchet.dbo.oper ON dc.oper=oper.upcode 
	INNER JOIN uchet.dbo.account ON oper.accd=account.code
	LEFT JOIN per ON per.code=dc.oper
	where dr.owner=23 AND account.code='22' and dr.date between @start and @end
	GROUP BY
	dc.code
	, dr.code
	, dr.date
	, dr.time
	, case when per.code is not null then 1 else 0 end
	, CASE oper.ComDeb WHEN 1 THEN dr.c_from WHEN 2 THEN dr.c_to WHEN 3 THEN dr.c_thro WHEN 4 THEN oper.ComDVal WHEN 5 THEN dc.corr ELSE dr.c_to END,
	dc.tovar, 
	(CASE WHEN n.en_subcode = 1 THEN dc.lot ELSE 0 END),
	dc.parcel,
	account.code

	union all
--Расходы
	SELECT 
	 oper=case when sum(dc.quantity)>=0 then 1 else 0 end
	, dc.code*10 as code
	, dr.code as drcode
	, dr.date
	, dr.time
	, case when per.code is not null then 1 else 0 end as per
	, account.code as account
	, (CASE oper.comcred WHEN 1 THEN dr.c_from WHEN 2 THEN dr.c_to WHEN 3 THEN dr.c_thro WHEN 4 THEN oper.ComDVal WHEN 5 THEN dc.corr ELSE dr.c_to END) as company
	, dc.tovar
	, (CASE WHEN n.en_subcode = 1 THEN dc.lot ELSE 0 END) as lot
	, dc.parcel
	, cost=case when sum(dc.quantity)>=0 then 0 else sum(dc.amount)/sum(dc.quantity) end
	, -sum(dc.quantity) as quantity
	from uchet.dbo.doc_ref dr (nolock) 
	inner join uchet.dbo.document dc (nolock)	on dr.code=dc.upcode
	INNER JOIN uchet.dbo.nomencl n (NOLOCK) ON dc.tovar=n.code
	INNER JOIN uchet.dbo.oper ON dc.oper=oper.upcode 
	INNER JOIN uchet.dbo.account ON oper.acck=account.code
	LEFT JOIN per ON per.code=dc.oper
	where dr.owner=23 AND account.code='22' and dr.date between @start and @end
	GROUP BY
	dc.code
	, dr.code
	, dr.date
	, dr.time
	, case when per.code is not null then 1 else 0 end
	, CASE oper.comcred WHEN 1 THEN dr.c_from WHEN 2 THEN dr.c_to WHEN 3 THEN dr.c_thro WHEN 4 THEN oper.ComDVal WHEN 5 THEN dc.corr ELSE dr.c_to END
	, dc.tovar
	, (CASE WHEN n.en_subcode = 1 THEN dc.lot ELSE 0 END)
	, dc.parcel
	, account.code
)

select * into #log from logdc where tovar=ISNULL(@tov,tovar)


--Сделать приход(не перемещение) по цене из документа.
--Сделать расход(реализация+перемещение) по фифо, с определением приходной цены.
--Сделать приход по перемещению. Взять себестоимость из расхода по перемещению.

IF OBJECT_ID('tempdb..#ostatq') IS NOT NULL 
DROP TABLE #ostatq

IF OBJECT_ID('tempdb..#dayCosts') IS NOT NULL 
DROP TABLE #dayCosts


create table #ostatq
(
	dt date
	,[time] int
	,account varchar(2)
	,company int
	,tovar int
	,lot int
	,parcel int
	,cost money
	,quantity money
)

create table #dayCosts
(
	id int
	,dt date
	,[time] int
	,account varchar(2)
	,company int
	,tovar int
	,lot int
	,parcel int
	,cost money
	,quantity money
	,runingTotal money
)

declare
	@currentCode int
	,@currentTime int
	,@date date
	,@time int
	,@dateStock date
	,@timeStock int
	,@oper int
	,@per int
	,@company int
	,@tovar int
	,@lot int
	,@parcel int
	,@cost money
	,@quantity money
	,@ost money
	,@companySource int

	IF OBJECT_ID('tempdb..#dayLog') IS NULL 
		select * into #dayLog from #log l where l.date=@current and l.tovar=0 order by code


delete from tmp.Ostatq_hist_fact where date between @start and @end and tovar=ISNULL(@tov,tovar)
insert into #ostatq
select dt, time, account, company, tovar, lot, parcel, cost, quantity from tmp.Ostatq_hist_fact where date=dateadd(day, -1, @start) and tovar=ISNULL(@tov,tovar)

while (select @current) <= @end
begin
	delete from #dayLog
	delete from #dayCosts
	
	insert into #dayLog
	select * from #log l where l.date=@current and tovar=ISNULL(@tov,tovar)
	order by code
	
	--Перед расчетом для нового дня удаляем полностью отгруженные остатки.
	delete from #ostatq where quantity<=0

	select top 1 @currentCode=code, @currentTime=[time] from #dayLog order by [time], code
		
	while @currentCode is not null and @currentTime is not null
	Begin
		
		--Вставить то чего не было
		select 
			@date=[date]
			,@time=[time]
			,@oper=oper
			,@per=per
			,@company=company
			,@tovar=tovar
			,@lot=lot
			,@parcel=parcel
			,@cost=cost
			,@quantity=quantity
		from #dayLog
		where code=@currentCode


		if @oper=0 and @per=0
		begin
			--Приходы
			--if @company=27647 or @current>'20140428'
			--	select 'Приход', @currentCode, @quantity, company=@company
			update o set quantity=quantity+@quantity from #ostatq o where o.account='22' and o.tovar=@tovar and o.company=@company and o.lot=@lot and o.parcel=@parcel and cost=@cost and dt=@date and [time]=@time
			if @@ROWCOUNT=0
				insert into #ostatq (dt, [time], account, company, tovar, lot, parcel, cost, quantity)
				values (@date, @time, '22', @company, @tovar, @lot, @parcel, @cost, @quantity)
			
		end
		if @oper=1
		begin
		--Отгрузки
		
			begin

			--	if @per=0
			--		select 'Расход', @currentCode, @quantity, company=@company
			--	else
			--		select 'Расход-перемещение', @currentCode, @quantity, company=@company

			;with nom AS (
			select * from #ostatq o 
			where o.account='22' 
			and o.tovar=@tovar 
			and o.company=@company
			and o.lot=@lot
			and o.parcel=@parcel
			and o.quantity>0
			)
			,nom2 AS (
			select id=@currentCode, q1.dt, q1.time, q1.account, q1.company, q1.tovar, q1.parcel, q1.lot, q1.cost, q1.quantity, runingTotal=isnull(sum(q2.quantity),0) from nom q1
			left join nom q2 on q2.dt<q1.dt or (q2.dt=q1.dt and q2.time<q1.time) or (q2.dt=q1.dt and q2.time=q1.time and q2.cost<=q1.cost)
			group by q1.dt, q1.time, q1.account, q1.company, q1.tovar, q1.parcel, q1.lot, q1.cost, q1.quantity
			)
			insert into #dayCosts (id, dt, time, account, company, tovar, parcel, lot, cost, quantity, runingTotal)
			select * from nom2 where runingTotal<(-1*@quantity)
			union all
			select top 1 id, dt, time, account, company, tovar, parcel, lot, cost, quantity=quantity-(runingTotal+@quantity), runingTotal from nom2 where runingTotal>=(-1*@quantity) order by runingTotal
			
			update o set quantity=o.quantity-c.quantity
			from #dayCosts c inner join #ostatq o
			ON o.account=c.account and o.tovar=c.tovar and o.company=c.company and o.lot=c.lot and o.parcel=c.parcel and o.cost=c.cost and o.dt=c.dt and o.[time]=c.time			
			where c.id=@currentCode
			 
			end
		end
		if @oper=0 and @per=1
		begin

			--	select 'Приход-перемещение', @currentCode, @quantity, company=@company
	
			update o set o.quantity=o.quantity+c.quantity
			from #dayCosts c inner join #ostatq o
			ON o.account=c.account and o.tovar=c.tovar and o.company=@company and o.lot=c.lot and o.parcel=c.parcel and o.cost=c.cost and o.dt=c.dt and o.[time]=c.time			
			where c.id=@currentCode-1
			
			insert into #ostatq (dt, [time], account, company, tovar, lot, parcel, cost, quantity)
			select c.dt, c.[time], c.account, @company, c.tovar, c.lot, c.parcel, c.cost, c.quantity
			from #dayCosts c left join #ostatq o
			ON o.account=c.account and o.tovar=c.tovar and o.company=@company and o.lot=c.lot and o.parcel=c.parcel and o.cost=c.cost and o.dt=c.dt and o.[time]=c.time			
			where o.tovar is null and c.id=@currentCode-1
		
	
		end

		
		if exists(select code from #dayLog where [time]>@currentTime or ([time]=@currentTime and code>@currentCode))
			select top 1 @currentCode=code, @currentTime=[time] from #dayLog where [time]>@currentTime or ([time]=@currentTime and code>@currentCode) order by [time], code
		else 
			select @currentCode=null, @currentTime=null
		
	end
	
	--if day(@current)=1		
	--select @current, @currentCode, * from #ostatq

	INSERT INTO [OLAP_DATA].[tmp].[ostatq_hist_fact]
			   ([date]
			   ,dt
			   ,[time]
			   ,[account]
			   ,[tovar]
			   ,[company]
			   ,[parcel]
			   ,[lot]
			   ,[cost]
			   ,[quantity])
	select @current, dt, time, account, tovar, company, parcel, lot, cost, quantity from #ostatq

	set @current = dateadd(day, 1, @current)
end