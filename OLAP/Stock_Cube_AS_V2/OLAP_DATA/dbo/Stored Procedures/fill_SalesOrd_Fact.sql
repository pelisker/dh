
--Заполнение таблицы фактов

CREATE PROCEDURE [dbo].[fill_SalesOrd_Fact]

AS
SET DATEFORMAT dmy;
	TRUNCATE TABLE SalesOrd_Fact
	;WITH
	opers AS (
		SELECT oper=upcode, account=acck FROM uchet.dbo.oper (NOLOCK) GROUP BY upcode, acck HAVING SUM(CASE WHEN oper.acck IN ('021','03') THEN 1 ELSE 0 END)>0
		),
	vzv AS (SELECT pn.link, amount=-SUM(dc.amount) FROM uchet.dbo.doc_ref pn (NOLOCK)
		LEFT JOIN uchet.dbo.document dc (NOLOCK) ON pn.code=dc.upcode 
		WHERE pn.type_doc='П/Н+' AND dc.oper=513 GROUP BY pn.link
	),
	orders AS (
		--Продажи
		SELECT
           [id]=s.code
		   ,[delivery_fact]=ISNULL(drd.fact_amount,0)
		   ,ai_trID=ISNULL(drd.ai_trID,'')
		   ,volOur=ISNULL(dro.volOur,0)
		   ,wtOur=ISNULL(dro.wtOur,0)
		   ,volTK=ISNULL(dro.volTK,0)
		   ,wtTK=ISNULL(dro.wtTK,0)		   		   
		FROM uchet.dbo.doc_ref s (NOLOCK)
		LEFT JOIN uchet.dbo.DrfDelivery drd (NOLOCK) ON s.code=drd.upcode
		LEFT JOIN uchet.dbo.DrfOrder dro (NOLOCK) ON dro.upcode=s.code
		WHERE
			s.type_doc IN ('СчМК','ЛИД','ЛИДА','СЧА','СМо1','СМо2','СМо3','СМо4','СМо5','СМо6','СМо7','СМо8','СМо9','СМо')
			and s.owner=23
			and s.date > '31.12.2014'
		),
	trans AS (
		--Продажи
		SELECT
           [date]=rn.date
           ,[date_rez]=CASE WHEN drp.rez_date='1900-01-01' THEN rn.date ELSE ISNULL(drp.rez_date,rn.date) END
           ,[id]=rn.code
           ,[nn]=rn.nn
           ,[managerID]=rn.dogovor
           ,[clientID]=rn.c_to
           ,[regionID]=ISNULL(reg1.id,0)
		   ,[utm_source]=REPLACE(ISNULL(dro.UtmSource,''),' ','')
		   ,[utm_medium]=REPLACE(ISNULL(dro.UtmMedium,''),' ','')
		   ,[utm_term]=ISNULL(dro.UtmTerm,'')
		   ,[utm_campaign]=ISNULL(dro.utm_campaign,'')
		   ,[referrer]=LTRIM(RTRIM(ISNULL(REPLACE(REPLACE(LEFT(Referrer,  CASE CHARINDEX('/',Referrer,CHARINDEX(':',Referrer)+3) WHEN 0 THEN LEN(referrer) ELSE CHARINDEX('/',Referrer,CHARINDEX(':',Referrer)+3)-1 END ),'https://',''),'http://',''),'')))
           ,[amount]=sum(CASE WHEN dc.tovar!=6653 THEN dc.amount ELSE 0 END)
		   ,[delivery]=sum(CASE WHEN dc.tovar=6653 THEN dc.amount ELSE 0 END)
		   ,[return]=ISNULL(sum(vzv.amount),0)
		   ,[amountwithoutreturn]=sum(CASE WHEN dc.tovar!=6653 THEN dc.amount ELSE 0 END)-ISNULL(sum(vzv.amount),0)
		   ,[delivery_fact]=ISNULL(MAX(ord.delivery_fact),0)
		   ,ai_trID=ISNULL(MAX(ord.ai_trID),'')
		   ,volOur=ISNULL(MAX(ord.volOur),0)
		   ,wtOur=ISNULL(MAX(ord.wtOur),0)
		   ,volTK=ISNULL(MAX(ord.volTK),0)
		   ,wtTK=ISNULL(MAX(ord.wtTK),0)		   		   
		FROM uchet.dbo.doc_ref rn (NOLOCK)
		INNER JOIN uchet.dbo.document dc (NOLOCK) ON rn.code=dc.upcode
		INNER JOIN opers ON opers.oper=dc.oper
		LEFT JOIN vzv ON rn.link!=0 AND vzv.link=rn.link 
		LEFT JOIN uchet.dbo.DrfParam drp (NOLOCK) ON drp.upcode=rn.code
		LEFT JOIN uchet.dbo.DrfOrder dro (NOLOCK) ON dro.upcode=rn.code
		LEFT JOIN uchet.dbo.DrfDelivery drd (NOLOCK) ON rn.code=drd.upcode
		LEFT JOIN orders ord ON ord.id=rn.link AND rn.link!=0
		LEFT JOIN (SELECT id=max(id), nameL3 FROM Region_Dim GROUP BY nameL3) reg1 
			ON ltrim(str(reg1.id))=ltrim(rtrim(drd.ai_city))
				OR (ISNULL(drd.ai_city,'')='' AND reg1.NameL3='Москва' )
		WHERE
			rn.type_doc!='П/Н+'
			and rn.owner=23
			and rn.date > '31.12.2014'
			and dc.quantity>0
		GROUP BY rn.code, rn.date, rn.nn, rn.c_to, ISNULL(reg1.id,0), rn.dogovor, drp.rez_date, 
			dro.utm_campaign, dro.UtmContent, dro.UtmMedium, dro.UtmSource, dro.UtmTerm, dro.Referrer

		--UNION ALL
		----Возвраты
		--SELECT
		--   [date]=rn.date
  --         ,[id]=rn.code
  --         ,[nn]=rn.nn
  --         ,[managerID]=rn.dogovor           
  --         ,[clientID]=pn.c_to
  --         ,[regionID]=ISNULL(reg1.id,0)
  --         ,[amount]=0
  --         ,[delivery]=0
  --         ,[return]=sum(dc.amount)
		--FROM uchet.dbo.doc_ref pn (NOLOCK) 
		----INNER JOIN uchet.dbo.doc_ref rn (NOLOCK) ON pn.link=rn.link
		--INNER JOIN uchet.dbo.company client (NOLOCK) ON pn.c_from=client.code
		--INNER JOIN uchet.dbo.document dc ON pn.code=dc.upcode
		--LEFT JOIN uchet.dbo.DrfDelivery drd (NOLOCK) ON rn.code=drd.upcode
		--LEFT JOIN (SELECT id=max(id), nameL3 FROM Region_Dim GROUP BY nameL3) reg1 
		--	ON reg1.NameL3=ltrim(rtrim(replace(replace(drd.ai_city,'г.',''),'г ','')))
		--		OR (ISNULL(drd.ai_city,'')='' AND reg1.NameL3='Москва' )
		--WHERE
		----pn.type_doc='П/Н+' and 
		--dc.oper=513
		--and pn.owner=23
		--and pn.date > '31.12.2014'
		--GROUP BY rn.code, rn.date, rn.nn, rn.c_to, ISNULL(reg1.id,0), rn.dogovor, drp.rez_date
		)

	INSERT INTO [OLAP_DATA].[dbo].[SalesOrd_fact]
           ([date]
           ,[date_rez]
           ,[id]
           ,[nn]
           ,[managerID]
           ,[clientID]
           ,[regionID]
           ,[utm_source]
           ,[utm_medium]
           ,[utm_term]
           ,[utm_campaign]
           ,[referrer]
           ,[amount]
           ,[delivery]
           ,[return]
           ,[amountwithoutreturn]
           ,[delivery_fact]
           ,[volOur]
           ,[wtOur]
           ,[volTK]
           ,[wtTK]
           )
	SELECT
			[date]
		   ,[date_rez]
           ,[id]
           ,[nn]
           ,[managerID]
           ,[clientID]
           ,[regionID]
           ,[utm_source]
           ,[utm_medium]
           ,[utm_term]
           ,[utm_campaign]
           ,[referrer]
           ,[amount]
           ,[delivery]
           ,[return]
           ,[amountwithoutreturn]
           ,[delivery_fact]
           ,[volOur]
           ,[wtOur]
           ,[volTK]
           ,[wtTK]
	FROM trans