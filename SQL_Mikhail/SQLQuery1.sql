USE [uchet_test]
GO
/****** Object:  StoredProcedure [dbo].[ad_getParTovar1]    Script Date: 09/17/2018 11:29:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec ad_getParTovar1 796431

ALTER procedure [dbo].[ad_getParTovar1]
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
WHERE o.balance=23 and o.account='22' and o.quantity>0


SELECT DISTINCT tovar,company,parcel,lot,quantity 
INTO #t 
FROM @ostatq
SELECT tovar,SUM(quantity) quantity 
INTO #t1 
FROM #t 
GROUP BY tovar

SELECT tovar,SUM(quantity) quantity1 
INTO #t2 
FROM @tov 
GROUP BY tovar
SELECT IDENTITY(int,1,1) id,#t1.tovar,isnull(#t1.quantity,0)-#t2.quantity1 as q  
INTO #t3 
FROM #t1 
RIGHT JOIN #t2 
ON #t1.tovar=#t2.tovar
--select * from #t3
DECLARE @a int=1
DECLARE @tovar1 int
DECLARE @q int
DECLARE @str varchar(300)
SET @a=1
WHILE (@a<=(SELECT MAX(id) FROM #t3))
BEGIN
	SELECT @tovar1=tovar,@q=q 
	FROM #t3 
	WHERE id=@a
	IF (@q<0)
	BEGIN
		SELECT @str='На складе не достаточно товара '+ convert(varchar(100),@tovar1)
		RAISERROR (@str, -- Message text.
               16, -- Severity.
               1 -- State.
               );
		RETURN
	END
	SET @a=@a+1
END

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

SELECT DISTINCT b.*,a.oper 
FROM @result b 
INNER JOIN (SELECT DISTINCT tovar,oper  FROM document WHERE upcode=@drcode) a 
ON b.tovar=a.tovar

if OBJECT_ID('tempdb..#t') is not null
drop table #t
if OBJECT_ID('tempdb..#t1') is not null
drop table #t1
if OBJECT_ID('tempdb..#t2') is not null
drop table #t2
if OBJECT_ID('tempdb..#t3') is not null
drop table #t3