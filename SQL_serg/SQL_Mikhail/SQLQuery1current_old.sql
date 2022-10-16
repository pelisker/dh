declare @drcode int=796431--796428
,@account varchar='22'
,@owner int = 23
declare @result table (tovar int, lot int, quantity int, parcel int, price int, corr int)
-----
   SELECT tovar, lot, oper, corr, price, sum(quantity) AS quantity into #t FROM document dc where dc.upcode=796431/*796428*/ GROUP BY tovar, lot, oper, corr, price

SELECT 
		/*ROW_NUMBER() over(ORDER BY ISNULL(dr.date,'01.01.2015'))  id,*/ distinct ISNULL(dr.date,'01.01.2015') dat, o.parcel, o.quantity,#t.quantity quantity1,o.balance,#t.tovar,#t.lot
into #t1	FROM 
		ostatq o (NOLOCK) 
	LEFT JOIN
		parcel p (NOLOCK)
			ON p.code=o.parcel
	LEFT JOIN
		document dc (NOLOCK)
			ON dc.code=p.upcode
	LEFT JOIN
		doc_ref dr (NOLOCK)
			ON dr.code=dc.upcode
	inner join #t on	o.tovar=#t.tovar and o.lot=#t.lot and o.account='22' and o.balance='23' and #t.corr=o.company	
	WHERE
		/*o.tovar = 49757 AND o.company =122 and*/ o.parcel<>0
		/*o.lot = @lot AND
		o.account = @account AND
		o.company = @company AND
		o.balance = @balance AND*/
		and
		o.quantity>0 --AND
		--(dateadd(S,ISNULL(dr.time,0) ,ISNULL(dr.date,'01.01.2015'))<=ISNULL(@date,GETDATE()) OR dr.date IS Null)
	ORDER BY ISNULL(dr.date,'01.01.2015')
	if (select COUNT(*) from #t)<(select count(*) from #t1)
	begin
	select DAT,parcel,quantity,sum(quantity1) as quantity1,tovar,lot into #t11 from #t1 group by DAT,parcel,quantity,tovar,lot 
	SELECT 
		ROW_NUMBER() over(ORDER BY ISNULL(#t11.dat,'01.01.2015'))  id,#t11.dat,#t11.parcel,#t11.quantity,#t11.quantity1,tovar,lot
into #t22 from #t11



select  IDENTITY(int, 1,1) Id ,DAT,parcel,quantity1,tovar,lot into #t31 from #t22 where id=0
declare @id int, @dat datetime,@parcel int,@quantity int ,@quantity1 int,@tovar int,@lot int
declare @a int=1,@l int
DECLARE vendor_cursor CURSOR FOR 
SELECT 
		 id,#t2.dat,#t2.parcel,#t2.quantity,#t2.quantity1,#t2.tovar,#t2.lot
from #t22
OPEN vendor_cursor

FETCH NEXT FROM vendor_cursor 
INTO @id, @dat,@parcel,@quantity,@quantity1,@tovar,@lot

WHILE @@FETCH_STATUS = 0
BEGIN
set @a=1
while (@a<=(select MAX(id) from #t22))

begin
select @l=quantity-@quantity1 from #t22 where id=@a
if @l>=0
begin
insert into #t31 --values(@dat,@parcel,@quantity1,@tovar,@lot)
select DAT,parcel,@quantity1,tovar,lot from #t22 where id=@a
update #t22 set quantity=quantity-@quantity1,quantity1=0  where id=@a
update #t22 set quantity1=0  where id=@id
break
end
if (@l<0 and (select  quantity from #t22 where id=@a)>0)
begin
insert into #t31
select dat,parcel,quantity,tovar,lot from #t22 where id=@a
select @quantity1=@quantity1-(select quantity from #t22 where id=@a)
update #t22 set quantity=0 where id=@a
if (select quantity1 from #t22 where id=@id)>0
begin
update #t22 set quantity1=quantity1-(select quantity from #t22 where id=@a) where id=@id
update #t22 set quantity=quantity-quantity1 where id=@id
insert into #t31
select dat,parcel,@quantity1,tovar,lot from #t22 where id=@id


end
--if (select quantity1 from #t2 where id=@id)>0
--begin

end

set @a=@a+1
end
 FETCH NEXT FROM vendor_cursor 
    INTO @id, @dat,@parcel,@quantity,@quantity1,@tovar,@lot
END
CLOSE vendor_cursor
DEALLOCATE vendor_cursor


	--select * from #t22
	end
	else
	begin
SELECT 
		ROW_NUMBER() over(ORDER BY ISNULL(#t1.dat,'01.01.2015'))  id,#t1.dat,#t1.parcel,#t1.quantity,#t1.quantity1,tovar,lot
into #t2 from #t1


select  IDENTITY(int, 1,1) Id ,DAT,parcel,quantity1,tovar,lot into #t3 from #t2 where id=0
declare @id1 int, @dat1 datetime,@parcel1 int,@quantity0 int ,@quantity11 int,@tovar1 int,@lot1 int
declare @a1 int=1,@l1 int
DECLARE vendor_cursor CURSOR FOR 
SELECT 
		 id,#t2.dat,#t2.parcel,#t2.quantity,#t2.quantity1,#t2.tovar,#t2.lot
from #t2
OPEN vendor_cursor

FETCH NEXT FROM vendor_cursor 
INTO @id1, @dat1,@parcel1,@quantity0,@quantity11,@tovar1,@lot1

WHILE @@FETCH_STATUS = 0
BEGIN
set @a1=1
while (@a1<=(select MAX(id) from #t2))

begin
select @l1=quantity-@quantity11 from #t2 where id=@a
if @l>=0
begin
insert into #t3 --values(@dat,@parcel,@quantity1,@tovar,@lot)
select DAT,parcel,@quantity11,tovar,lot from #t2 where id=@a1
update #t2 set quantity=quantity-@quantity11,quantity1=0  where id=@a1
update #t2 set quantity1=0  where id=@id1
break
end
if (@l1<0 and (select  quantity from #t2 where id=@a1)>0)
begin
insert into #t3
select dat,parcel,quantity,tovar,lot from #t2 where id=@a
select @quantity11=@quantity11-(select quantity from #t2 where id=@a1)
update #t2 set quantity=0 where id=@a1
if (select quantity1 from #t2 where id=@id1)>0
begin
update #t2 set quantity1=quantity1-(select quantity from #t2 where id=@a1) where id=@id1
update #t2 set quantity=quantity-quantity1 where id=@id1
insert into #t3
select dat,parcel,@quantity11,tovar,lot from #t2 where id=@id


end
--if (select quantity1 from #t2 where id=@id)>0
--begin

end

set @a1=@a1+1
end
 FETCH NEXT FROM vendor_cursor 
    INTO @id1, @dat1,@parcel1,@quantity0,@quantity11,@tovar1,@lot1
END
CLOSE vendor_cursor
DEALLOCATE vendor_cursor


end
-----
select * from #t3
--select * from @result
select * from #t
select * from #t2
drop table #t
drop table #t1
drop table #t2
drop table #t3