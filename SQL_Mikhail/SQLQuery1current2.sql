--exec ad_getParTovar1 796431

alter procedure ad_getParTovar1
@drcode int

as

DECLARE @tov table (tovar int, lot int, price money, corr int, quantity int)
DECLARE @result table (tovar int, parcel int, lot int, price money, corr int, quantity int)

INSERT INTO @tov
SELECT tovar, lot, price, corr, quantity FROM document WHERE upcode=@drcode--796431

DECLARE @ostatq table (tovar int, company int, parcel int, lot int, quantity int)
INSERT INTO @ostatq

SELECT o.tovar, o.company, o.parcel, o.lot, o.quantity 
FROM ostatq o inner join @tov t on t.tovar=o.tovar AND t.corr=o.company and t.lot=o.lot
WHERE o.balance=23 and o.account='22' and o.parcel!=0 and o.quantity>0
select distinct tovar,company,parcel,lot,quantity into #t from @ostatq
select tovar,SUM(quantity) quantity into #t1 from #t group by tovar
select tovar,SUM(quantity) quantity1 into #t2 from @tov group by tovar
select IDENTITY(int,1,1) id,#t1.tovar,isnull(#t1.quantity,0)-#t2.quantity1 as q  into #t3 from #t1 right join #t2 on #t1.tovar=#t2.tovar
--select * from #t3
declare @a int=1
declare @tovar1 int
declare @q int
declare @str varchar(300)
set @a=1
while (@a<=(select MAX(id) from #t3))
begin
select @tovar1=tovar,@q=q from #t3 where id=@a
if (@q<0)
begin
select @str='На складе не достаточно товара '+ convert(varchar(100),@tovar1)
 RAISERROR (@str, -- Message text.
               16, -- Severity.
               1 -- State.
               );
return
end
set @a=@a+1
end

DECLARE
@tovar int,
@corr int,
@parcel int,
@lot int,
@price money,
@quantity int,
@ost int

WHILE exists(select tovar from @tov where quantity>0) AND exists(select tovar from @ostatq where quantity>0)
BEGIN
	SELECT top 1 @tovar=tovar, @lot=lot, @corr=corr, @price=price, @quantity=quantity FROM @tov WHERE quantity>0
	SELECT top 1 @ost=quantity, @parcel=parcel FROM @ostatq WHERE @tovar=tovar AND @lot=lot AND @corr=company AND quantity>0 ORDER BY parcel
	
		IF @ost>@quantity
	BEGIN
		UPDATE @tov SET quantity=0 WHERE @tovar=tovar AND @lot=lot AND @corr=corr AND @price=price
		INSERT INTO @result (tovar, parcel, lot, price, corr, quantity ) VALUES (@tovar, @parcel, @lot, @price, @corr, @quantity)
		UPDATE @ostatq SET quantity=quantity-@quantity WHERE @tovar=tovar AND @lot=lot AND @corr=company AND @parcel=parcel
	END
	
		ELSE
	BEGIN
		UPDATE @tov SET quantity=quantity-@ost WHERE @tovar=tovar AND @lot=lot AND @corr=corr AND @price=price
		INSERT INTO @result (tovar, parcel, lot, price, corr, quantity ) VALUES (@tovar, @parcel, @lot, @price, @corr, @ost)
		UPDATE @ostatq SET quantity=0 WHERE @tovar=tovar AND @lot=lot AND @corr=company AND @parcel=parcel	
	END
END

select distinct b.*,a.oper from @result b inner join (select distinct tovar,oper  FROM document WHERE upcode=@drcode) a on b.tovar=a.tovar

if OBJECT_ID('tempdb..#t') is not null
drop table #t
if OBJECT_ID('tempdb..#t1') is not null
drop table #t1
if OBJECT_ID('tempdb..#t2') is not null
drop table #t2
if OBJECT_ID('tempdb..#t3') is not null
drop table #t3