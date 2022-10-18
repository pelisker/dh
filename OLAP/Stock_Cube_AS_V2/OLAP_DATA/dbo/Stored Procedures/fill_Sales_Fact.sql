


--Заполнение таблицы фактов

CREATE PROCEDURE [dbo].[fill_Sales_Fact]

AS
--SET DATEFORMAT dmy;
--	TRUNCATE TABLE Sales_fact
--	;WITH
--	opers AS (
--		SELECT oper=upcode, account=acck FROM uchet.dbo.oper (NOLOCK) GROUP BY upcode, acck HAVING SUM(CASE WHEN oper.acck IN ('021'/*,'03'*/) THEN 1 ELSE 0 END)>0
--		),
--	parcels AS (
--		SELECT
--			DISTINCT
--			id=ISNULL(dr.code,-1),
--			parcel=p.code,
--			cost=ISNULL(dc.price,0)
--		FROM uchet.dbo.Parcel p (NOLOCK) 
--		LEFT JOIN uchet.dbo.document dc (NOLOCK) 
--			ON dc.code=p.upcode
--		LEFT JOIN uchet.dbo.doc_ref dr (NOLOCK) 
--			ON dc.upcode=dr.code
--	),
--	trans AS (
--		--Продажи
--		SELECT
--           [date]=datepart(YEAR,rn.date)*10000 + datepart(M,rn.date)*100 + datepart(D,rn.date)
--           ,[id]=dc.code
--           ,[nn]=rn.nn
--           ,[clientID]=rn.c_to
--           ,[productID]=dc.tovar
--           --,[regionID]=CASE WHEN reg2.id IS NOT NULL THEN reg2.id ELSE ISNULL(reg1.id,0) END
--           ,[regionID]=ISNULL(reg1.id,0)
--           ,[amount]=dc.amount
--           ,[quantity]=CASE WHEN rn.type_doc='ПСР' THEN 0 ELSE dc.quantity END --Убраны количества из ПСР
--           ,[costamount]=ISNULL(Round(dc.quantity*parcels.cost,2),0)
--           ,[profit]=ISNULL(dc.amount-Round(dc.quantity*parcels.cost,2),0)
--           ,[orderID]=rn.code
--           ,[ParcelID]=ISNULL(parcels.id,0)
--		FROM uchet.dbo.doc_ref rn
----		INNER JOIN uchet.dbo.company client (NOLOCK) ON rn.c_to=client.code
--		INNER JOIN uchet.dbo.document dc (NOLOCK) ON rn.code=dc.upcode
--		INNER JOIN opers ON opers.oper=dc.oper
--		LEFT JOIN parcels ON dc.parcel=parcels.parcel
--		LEFT JOIN uchet.dbo.DrfDelivery drd (NOLOCK) ON rn.code=drd.upcode
--		LEFT JOIN (SELECT id=max(id), nameL3 FROM Region_Dim GROUP BY nameL3) reg1 
--			--ON reg1.NameL3=ltrim(rtrim(replace(replace(drd.ai_city,'г.',''),'г ',''))) --collate SQL_Latin1_General_CP1251_CI_AS
--			ON ltrim(str(reg1.id))=ltrim(rtrim(drd.ai_city))
--				OR (ISNULL(drd.ai_city,'')='' AND reg1.NameL3='Москва' )
--/*		LEFT JOIN Region_Dim reg2 ON reg1.Name=dro.City --collate SQL_Latin1_General_CP1251_CI_AS*/
--		WHERE
--		rn.type_doc!='П/Н+'
--		and rn.owner=23
--		and rn.date > '31.12.2014'
--		and dc.quantity>0
--		--UNION ALL
--		----Возвраты
--		--SELECT
--		--   [date]=datepart(YEAR,pn.date)*10000 + datepart(M,pn.date)*100 + datepart(D,pn.date)
--		--   --pn.date
--  --         ,[id]=dc.code
--  --         ,[nn]=pn.nn
--  --         --,[type]=pn.type_doc
--  --         ,[clientID]=pn.c_from
--  --         ,[productID]=dc.tovar          
--  --         ,[regionID]=0--ISNULL(reg1.id,0)
--  --         ,[amount]=dc.amount
--  --         ,[quantity]=dc.quantity
--  --         ,[costamount]=0 --ISNULL(Round(dc.quantity*parcels.cost,2),0)
--  --         ,[profit]=0 --ISNULL(dc.amount-Round(dc.quantity*parcels.cost,2),0)
--  --         ,[orderID]=0 --rn.code
--  --         ,[ParcelID]=0 --ISNULL(parcels.id,0)
--		--FROM uchet.dbo.doc_ref pn
--		--INNER JOIN uchet.dbo.company client (NOLOCK) ON pn.c_from=client.code
--		--INNER JOIN uchet.dbo.document dc ON pn.code=dc.upcode
--		--INNER JOIN opers ON opers.oper=dc.oper
--		--LEFT JOIN uchet.dbo.DrfDelivery drd (NOLOCK) ON pn.code=drd.upcode		
--		--LEFT JOIN (SELECT id=max(id), nameL3 FROM Region_Dim GROUP BY nameL3) reg1 
--		--	ON ltrim(str(reg1.id))=ltrim(rtrim(drd.ai_city))
--		--		OR (ISNULL(drd.ai_city,'')='' AND reg1.NameL3='Москва' )
		
--		--WHERE
--		--pn.type_doc='П/Н+'
--		--and pn.owner=23
--		--and pn.date > '31.12.2014'
--		)

SET DATEFORMAT dmy;
	delete from Sales_fact where date>=cast(convert(varchar(10),dateadd(YEAR,-4,GETDATE()),112) AS int)

declare @reg as table (id int primary key, nameL3 varchar(200))

insert into @reg
SELECT distinct id=max(id), nameL3 FROM Region_Dim GROUP BY nameL3
	
	;WITH
	opers AS (
		SELECT oper=upcode, account=acck FROM uchet.dbo.oper (NOLOCK) GROUP BY upcode, acck HAVING SUM(CASE WHEN oper.acck IN ('021'/*,'03'*/) THEN 1 ELSE 0 END)>0
		),
	pays AS (
		SELECT
			link=isnull(dr.link,0), date=MIN(dr.date)
		FROM uchet.dbo.doc_ref dr (NOLOCK)
		INNER JOIN uchet.dbo.document dc (NOLOCK) 
			ON dc.upcode=dr.code
		WHERE isnull(dr.link,0)!=0 AND dr.owner=23 AND (dr.type_doc LIKE 'ВхПл' OR dr.type_doc LIKE 'ПКО%')
		GROUP BY isnull(dr.link,0)
			),
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
	drd AS (select reg=case when ISNUMERIC(ai_city)=1 and LEN(ai_city)<11 then CAST(ai_city AS Int) else -1 end, *  from uchet.dbo.drfdelivery (NOLOCK)),
	trans AS (
		--Продажи
		SELECT
           [date]=cast(convert(varchar(10),rn.date,112) AS int) --datepart(YEAR,rn.date)*10000 + datepart(M,rn.date)*100 + datepart(D,rn.date)
           ,[dateOfPay]=ISNULL(cast(convert(varchar(10),pays.date,112) AS int),cast(convert(varchar(10),rn.date,112) AS int))
           ,[id]=dc.code
           ,[nn]=rn.nn
           ,[manager]=isnull(dog.name,'')
           ,[salesTerm]=ISNULL(drp.salesTerm,'не задано')
           ,[managerID]=rn.dogovor
           ,[clientID]=rn.c_to
           ,[productID]=dc.tovar
           --,[regionID]=CASE WHEN reg2.id IS NOT NULL THEN reg2.id ELSE ISNULL(reg1.id,0) END
           ,[regionID]=ISNULL(reg1.id,0)
           ,[amount]=dc.amount
           ,[quantity]=CASE WHEN rn.type_doc='ПСР' THEN 0 ELSE dc.quantity END /*Убраны количества из ПСР*/
           ,[quantityNoLegs]=CASE WHEN ISNULL(np.isLegs,0)=1 or rn.type_doc='ПСР' THEN 0 ELSE dc.quantity END /*Убраны количества из ПСР, убраны количества для ножек*/
           ,[costamount]=ISNULL(Round(dc.quantity*parcels.cost,2),0)
           ,[profit]=ISNULL(dc.amount-ISNULL(Round(dc.quantity*parcels.cost,2),0),0)
           ,[orderID]=rn.code
           ,[ParcelID]=ISNULL(parcels.id,0)
		FROM uchet.dbo.doc_ref rn (NOLOCK)
		INNER JOIN uchet.dbo.document dc (NOLOCK) ON rn.code=dc.upcode
		INNER JOIN opers ON opers.oper=dc.oper
		LEFT JOIN pays ON rn.link=pays.link
		LEFT JOIN uchet.dbo.nomparam np ON np.upcode=dc.tovar
		LEFT JOIN uchet.dbo.drfparam drp (NOLOCK) ON drp.upcode=rn.code
		LEFT JOIN uchet.dbo.dogovor dog (NOLOCK) ON dog.code=rn.dogovor
		LEFT JOIN parcels ON dc.parcel=parcels.parcel
		LEFT JOIN drd ON rn.code=drd.upcode
		LEFT JOIN @reg reg1 
			ON (ISNULL(drd.reg,0)!=0 and reg1.id=drd.reg)
				OR (ISNULL(drd.reg,0)=0 AND reg1.id=1136/*Москва*/ )
		WHERE
		rn.type_doc!='П/Н+'
		and rn.owner=23
		and rn.date >= dateadd(YEAR,-4,GETDATE())
		and dc.quantity>0
		UNION ALL
		--Возвраты
		SELECT
		   [date]=cast(convert(varchar(10),pn.date,112) AS int)
		   ,[dateOfPay]=cast(convert(varchar(10),pn.date,112) AS int)
           ,[id]=dc.code
           ,[nn]=pn.nn
           ,[manager]=isnull(dog.name,'')
           ,[salesTerm]=ISNULL(drp.salesTerm,'не задано')
           ,[managerID]=pn.dogovor
           ,[clientID]=pn.c_from
           ,[productID]=dc.tovar          
           ,[regionID]=ISNULL(reg1.id,0)
           ,[amount]=dc.amount
           ,[quantity]=-dc.quantity
           ,[quantityNoLegs]=CASE WHEN ISNULL(np.isLegs,0)=1 THEN 0 ELSE -dc.quantity END
           ,[costamount]=ISNULL(Round(-dc.quantity*parcels.cost,2),0)
           ,[profit]=ISNULL(dc.amount-Round(-dc.quantity*parcels.cost,2),0)
           ,[orderID]=pn.code
           ,[ParcelID]=ISNULL(parcels.id,0)
		FROM uchet.dbo.doc_ref pn
		INNER JOIN uchet.dbo.company client (NOLOCK) ON pn.c_from=client.code
		INNER JOIN uchet.dbo.document dc ON pn.code=dc.upcode
		INNER JOIN opers ON opers.oper=dc.oper
		LEFT JOIN uchet.dbo.nomparam np ON np.upcode=dc.tovar
		LEFT JOIN uchet.dbo.drfparam drp (NOLOCK) ON drp.upcode=pn.code
		LEFT JOIN uchet.dbo.dogovor dog (NOLOCK) ON dog.code=pn.dogovor
		LEFT JOIN parcels ON dc.parcel=parcels.parcel
		LEFT JOIN drd ON pn.code=drd.upcode
		LEFT JOIN @reg reg1 
			ON (ISNULL(drd.reg,0)!=0 and reg1.id=drd.reg)
				OR (ISNULL(drd.reg,0)=0 AND reg1.id=1136/*Москва*/ )
		
		WHERE
		pn.type_doc='П/Н+'
		and pn.owner=23
		and pn.date >= dateadd(YEAR,-4,GETDATE())
		)

	INSERT INTO [OLAP_DATA].[dbo].[Sales_fact]
           ([date]
           ,[dateOfPay]
           ,[id]
           ,[nn]
           ,[manager]
           ,[salesTerm]
           ,[managerID]
           ,[clientID]
           ,[productID]
           ,[regionID]
           ,[amount]
           ,[quantity]
           ,[quantityNoLegs]
           ,[orderID]
           ,[ParcelID]
           ,costamount
           ,profit
			)
	SELECT
			[date]
		   ,[dateOfPay]
           ,[id]
           ,[nn]
           ,[manager]
           ,[salesTerm]
           ,[managerID]
           ,[clientID]
           ,[productID]
           ,[regionID]
           ,[amount]
           ,[quantity]
           ,[quantityNoLegs]
           ,[orderID]
           ,[ParcelID]
           ,costamount
	       ,profit
	FROM trans