
----Заполнение таблицы фактов. Товары в пути.
----Импорт
----П/Н, 
----467 операция 
----Дата прихода - дата
----Дата оплаты - дата создания

----Локальные поставщики
----Тип документа ПНм7
----30 операция
----Дата прихода - дата
----Дата оплаты - дата создания

CREATE PROCEDURE [dbo].[fill_SupplyWay_Fact]

AS

	SET DATEFORMAT dmy;

	TRUNCATE TABLE SupplyWay_fact
	;WITH
	dateOfCreates AS (
		select 
		code, date = max(date)
		from uchet.dbo.spy s (NOLOCK) where s.alias='doc_ref' AND s.oper=1
		group by code 
	),
	
	trans AS (
		--Закупки Импорт
		--Закупки Локальные поставщики
		SELECT
           [dateOfPay]=datepart(YEAR,d.date)*10000 + datepart(M,d.date)*100 + datepart(D,d.date)
           ,[dateOfReceipt]=datepart(YEAR,pn.date)*10000 + datepart(M,pn.date)*100 + datepart(D,pn.date)
           ,[id]=dc.code
           ,[nn]=pn.nn
           ,[productID]=dc.tovar
           ,[quantity]=dc.quantity
           ,[costamount]=dc.price
           ,[currency]=dc.valuta
		FROM uchet.dbo.doc_ref pn
		INNER JOIN uchet.dbo.document dc (NOLOCK) ON pn.code=dc.upcode
		INNER JOIN dateOfCreates d ON pn.code=d.code
		WHERE
		pn.type_doc IN ('П/Н','ПНм7')
		and pn.owner=23
		and pn.date > '31.12.2014'
		and dc.quantity>0
		and dc.amount!=0
		and dc.oper IN (467,30)
		)		
	INSERT INTO [OLAP_DATA].[dbo].[SupplyWay_fact]
           ([dateOfPay]
           ,[dateOfReceipt]
           ,[id]
           ,[nn]
           ,[productID]
           ,[quantity]
           ,[costamount]
           ,[currency]
			)
	SELECT
			[dateOfPay]
		   ,[dateOfReceipt]
           ,[id]
           ,[nn]
           ,[productID]
           ,[quantity]
           ,[costamount]
           ,[currency]
	FROM trans