
--Расчет истории остатков по проводкам, 22 счет только в разрезрезе товара(склады, партии и прочее не учитывается)
--В качестве даты появления товара на остатке берется дата появления товара в пути.
CREATE procedure [tmp].[fill_OstatqHistWithoutCompany_fact] 
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
inv as (
	--Даты когда машина появилась в пути, то есть товар стал доступен для продажи.
		select link=case when ISNULL(link,0)=0 then dr.code else link end
		, date=max(s.date)
		from uchet.dbo.doc_ref dr (nolock)
		inner join uchet.dbo.spy s (nolock) ON dr.code=s.code and s.alias='doc_ref' and s.oper=1
		WHERE 
		owner=23 and type_doc IN ('ИНВ','П/Н+') 
		group by case when ISNULL(link,0)=0 then dr.code else link end
	),
logdc AS  (
--Приходы
	SELECT 
	--dr.type_doc,
	--prih=case when dc.oper IN (79,220) THEN 1 ELSE 0 END,
	oper=case when sum(dc.quantity)>=0 then 0 else 1 end
	--invdate=inv.date
	, dc.code*10+1 as code
	, dr.code as drcode
	, date=cast(ISNULL(inv.date,dr.date) as date)
	, oper.accd as account
	, dc.tovar
	, (CASE WHEN n.en_subcode = 1 THEN dc.lot ELSE 0 END) as lot
	, sum(dc.quantity) as quantity
	from uchet.dbo.doc_ref dr (nolock) 
	INNER JOIN uchet.dbo.document dc (nolock) on dr.code=dc.upcode
	LEFT JOIN inv ON (dr.type_doc='П/Ни' or dc.oper=220) and inv.link=case when isnull(dr.link,0)=0 then dr.code else dr.link end
	INNER JOIN uchet.dbo.nomencl n (NOLOCK) ON dc.tovar=n.code
	INNER JOIN uchet.dbo.oper (NOLOCK) ON dc.oper=oper.upcode 
	where dr.owner=23 AND oper.accd='22' and dr.date between @start and @end
	GROUP BY
	dc.code
	, dr.code
	, dr.date
	, inv.date
	, dr.time
	, dc.tovar
	,(CASE WHEN n.en_subcode = 1 THEN dc.lot ELSE 0 END),
	dc.parcel,
	oper.accd

	union all
--Расходы
	SELECT 
	 oper=case when sum(dc.quantity)>=0 then 1 else 0 end
	, dc.code*10 as code
	, dr.code as drcode
	, dr.date
	, account.code as account
	, dc.tovar
	, (CASE WHEN n.en_subcode = 1 THEN dc.lot ELSE 0 END) as lot
	, -sum(dc.quantity) as quantity
	from uchet.dbo.doc_ref dr (nolock) 
	inner join uchet.dbo.document dc (nolock)	on dr.code=dc.upcode
	INNER JOIN uchet.dbo.nomencl n (NOLOCK) ON dc.tovar=n.code
	INNER JOIN uchet.dbo.oper ON dc.oper=oper.upcode 
	INNER JOIN uchet.dbo.account ON oper.acck=account.code
	where dr.owner=23 AND account.code='22' and dr.date between @start and @end
	GROUP BY
	dc.code
	, dr.code
	, dr.date
	, dr.time
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


create table #ostatq
(
	account varchar(2)
	,tovar int
	,lot int
	,quantity money
)

declare
	@currentCode int
	,@date date
	,@oper int
	,@tovar int
	,@lot int
	,@quantity money
	,@ost money

	IF OBJECT_ID('tempdb..#dayLog') IS NULL 
		select * into #dayLog from #log l where l.date=@current and l.tovar=0 order by code


delete from tmp.OstatqHistWithoutCompany_fact where date between @start and @end and tovar=ISNULL(@tov,tovar)
insert into #ostatq
select account, tovar, lot, quantity from tmp.OstatqHistWithoutCompany_fact where date=dateadd(day, -1, @start) and tovar=ISNULL(@tov,tovar)

while (select @current) <= @end
begin
	delete from #dayLog
	
	insert into #dayLog
	select * from #log l where l.date=@current and tovar=ISNULL(@tov,tovar)
	order by code
	
	--Перед расчетом для нового дня удаляем полностью отгруженные остатки.
	delete from #ostatq where quantity<=0

	select top 1 @currentCode=code from #dayLog order by code
		
	while @currentCode is not null 
	Begin
		
		--Вставить то чего не было
		select 
			@date=[date]
			,@oper=oper
			,@tovar=tovar
			,@lot=lot
			,@quantity=quantity
		from #dayLog
		where code=@currentCode


		if @oper=0
		begin
			--Приходы
			--if @company=27647 or @current>'20140428'
			--	select 'Приход', @currentCode, @quantity, company=@company
			update o set quantity=quantity+@quantity from #ostatq o where o.account='22' and o.tovar=@tovar and o.lot=@lot
			if @@ROWCOUNT=0
				insert into #ostatq (account, tovar, lot, quantity)
				values ('22', @tovar, @lot, @quantity)
			
		end
		if @oper=1
		begin
		--Отгрузки
		
			begin

			----	if @per=0
			----		select 'Расход', @currentCode, @quantity, company=@company
			----	else
			----		select 'Расход-перемещение', @currentCode, @quantity, company=@company

			--;with nom AS (
			--select * from #ostatq o 
			--where o.account='22' 
			--and o.tovar=@tovar 
			--and o.lot=@lot
			--and o.quantity>0
			--)
			--,nom2 AS (
			--select id=@currentCode, q1.account, q1.tovar, q1.lot, q1.quantity, runingTotal=isnull(sum(q2.quantity),0) from nom q1
			--left join nom q2 on q2.dt<=q1.dt
			--group q1.account, q1.tovar, q1.lot, q1.quantity
			--)
			--insert into #dayCosts (id, account, tovar, lot, quantity, runingTotal)
			--select * from nom2 where runingTotal<(-1*@quantity)
			--union all
			--select top 1 id, account, tovar, lot, quantity=quantity-(runingTotal+@quantity), runingTotal from nom2 where runingTotal>=(-1*@quantity) order by runingTotal
			
			--update o set quantity=o.quantity-c.quantity
			--from #ostatq o
			--where o.account='22' 
			--and o.tovar=@tovar 
			--and o.lot=@lot
			--and o.quantity>0
			--and c.id=@currentCode
			update o set quantity=quantity+@quantity from #ostatq o where o.account='22' and o.tovar=@tovar and o.lot=@lot
			if @@ROWCOUNT=0
				insert into #ostatq (account, tovar, lot, quantity)
				values ('22', @tovar, @lot, @quantity)


			 
			end
		end

		
		if exists(select code from #dayLog where code>@currentCode)
			select top 1 @currentCode=code from #dayLog where code>@currentCode order by code
		else 
			select @currentCode=null
		
	end
	
	--if day(@current)=1		
	--select @current, @currentCode, * from #ostatq

	INSERT INTO [OLAP_DATA].[tmp].[OstatqHistWithoutCompany_fact]
			   ([date]
			   ,[account]
			   ,[tovar]
			   ,[lot]
			   ,[quantity])
	select @current, account, tovar, lot, quantity from #ostatq

	set @current = dateadd(day, 1, @current)
end