
--Заполнение таблицы фактов

CREATE PROCEDURE [dbo].[fill_Supply_Fact]

AS
SET DATEFORMAT dmy;
	TRUNCATE TABLE Supply_fact
	;WITH
	--opers AS (
	--	SELECT oper=upcode, account=acck FROM uchet.dbo.oper (NOLOCK) GROUP BY upcode, acck HAVING SUM(CASE WHEN oper.acck IN ('021'/*,'03'*/) THEN 1 ELSE 0 END)>0
	--	),
	parcels AS (
		SELECT
			DISTINCT
			id=ISNULL(dr.code,-1),
			parcel=p.code,
			cost=ISNULL(dc.price,0)
		FROM uchet.dbo.Parcel p (NOLOCK) 
		LEFT JOIN uchet.dbo.document dc (NOLOCK) 
			ON dc.code=p.upcode
		LEFT JOIN uchet.dbo.doc_ref dr (NOLOCK) 
			ON dc.upcode=dr.code
	),
	trans AS (
		--Закупки
		SELECT
           [date]=datepart(YEAR,pn.date)*10000 + datepart(M,pn.date)*100 + datepart(D,pn.date)
           ,[id]=dc.code
           ,[nn]=pn.nn
           ,[productID]=dc.tovar
           ,[ParcelID]=ISNULL(parcels.id,0)
           ,[quantity]=dc.quantity
           ,[amount]=dc.amount
           ,[costamount]=dc.price
           ,[currency]=dc.valuta
		FROM uchet.dbo.doc_ref pn
		INNER JOIN uchet.dbo.company supplier (NOLOCK) ON pn.c_from=supplier.code
		INNER JOIN uchet.dbo.document dc (NOLOCK) ON pn.code=dc.upcode
		LEFT JOIN parcels ON dc.parcel=parcels.parcel
		WHERE
		pn.type_doc IN ('П/Н+','П/Ни')
		and pn.owner=23
		and pn.date > '31.12.2014'
		and dc.quantity>0
		and dc.oper IN (220,79)
		--UNION ALL
		----Возвраты
		--SELECT
		--   [date]=datepart(YEAR,pn.date)*10000 + datepart(M,pn.date)*100 + datepart(D,pn.date)
		--   --pn.date
  --         ,[id]=dc.code
  --         ,[nn]=pn.nn
  --         --,[type]=pn.type_doc
  --         ,[clientID]=pn.c_from
  --         ,[productID]=dc.tovar          
  --         ,[regionID]=0--ISNULL(reg1.id,0)
  --         ,[amount]=dc.amount
  --         ,[quantity]=dc.quantity
  --         ,[costamount]=0 --ISNULL(Round(dc.quantity*parcels.cost,2),0)
  --         ,[profit]=0 --ISNULL(dc.amount-Round(dc.quantity*parcels.cost,2),0)
  --         ,[orderID]=0 --rn.code
  --         ,[ParcelID]=0 --ISNULL(parcels.id,0)
		--FROM uchet.dbo.doc_ref pn
		--INNER JOIN uchet.dbo.company client (NOLOCK) ON pn.c_from=client.code
		--INNER JOIN uchet.dbo.document dc ON pn.code=dc.upcode
		--INNER JOIN opers ON opers.oper=dc.oper
		--LEFT JOIN uchet.dbo.DrfDelivery drd (NOLOCK) ON pn.code=drd.upcode		
		--LEFT JOIN (SELECT id=max(id), nameL3 FROM Region_Dim GROUP BY nameL3) reg1 
		--	ON ltrim(str(reg1.id))=ltrim(rtrim(drd.ai_city))
		--		OR (ISNULL(drd.ai_city,'')='' AND reg1.NameL3='Москва' )
		
		--WHERE
		--pn.type_doc='П/Н+'
		--and pn.owner=23
		--and pn.date > '31.12.2014'
		)

	INSERT INTO [OLAP_DATA].[dbo].[Supply_fact]
           ([date]
           ,[id]
           ,[nn]
           ,[productID]
           ,[parcelID]
           ,[quantity]
           ,[amount]
           ,[costamount]
           ,[currency]
			)
	SELECT
			[date]
           ,[id]
           ,[nn]
           ,[productID]
           ,[parcelID]
           ,[quantity]
           ,[amount]
           ,[costamount]
           ,[currency]
	FROM trans