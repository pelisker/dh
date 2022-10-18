
--Заполнение таблицы фактов

CREATE PROCEDURE [dbo].[fill_Orders_Fact]

AS
SET DATEFORMAT dmy;
	TRUNCATE TABLE Orders_Fact
	;WITH
	trans AS (
		--Продажи
		SELECT
           [date]=s.date
           ,[date_rez]=CASE WHEN drp.rez_date='1900-01-01' THEN s.date ELSE ISNULL(drp.rez_date,s.date) END
           ,[id]=s.code
           ,s.type_doc
           ,[nn]=s.nn
           ,[managerID]=s.dogovor
           ,[clientID]=s.c_to
           ,[regionID]=ISNULL(reg1.id,0)
           ,[amount]=sum(CASE WHEN dc.tovar!=6653 THEN dc.amount ELSE 0 END)
		   ,[delivery]=sum(CASE WHEN dc.tovar=6653 THEN dc.amount ELSE 0 END)
		FROM uchet.dbo.doc_ref s (NOLOCK)
		INNER JOIN uchet.dbo.document dc (NOLOCK) ON s.code=dc.upcode
		LEFT JOIN uchet.dbo.DrfParam drp (NOLOCK) ON drp.upcode=s.code
		LEFT JOIN uchet.dbo.DrfDelivery drd (NOLOCK) ON s.code=drd.upcode
		LEFT JOIN (SELECT id=max(id), nameL3 FROM Region_Dim GROUP BY nameL3) reg1 
			ON ltrim(str(reg1.id))=ltrim(rtrim(drd.ai_city))
				OR (ISNULL(drd.ai_city,'')='' AND reg1.NameL3='Москва' )
		--LEFT JOIN uchet.dbo.DrfOrder dro (NOLOCK) ON s.code=dro.upcode
		--LEFT JOIN utm_Dim ON ISNULL(dro.Referrer,'')=utm_Dim.referrer AND ISNULL(dro.utm_campaign,'')=utm_Dim.utm_campaign
		--	AND ISNULL(dro.UtmContent,'')=utm_Dim.utm_content AND ISNULL(dro.UtmSource,'')=utm_Dim.utm_source
		--	AND ISNULL(dro.UtmTerm,'')=utm_Dim.utm_term AND ISNULL(dro.UtmMedium,'')=utm_Dim.utm_medium
		WHERE
			s.type_doc IN ('СчМК','ЛИД','ЛИДА','СЧА','СМо1','СМо2','СМо3','СМо4','СМо5','СМо6','СМо7','СМо8','СМо9','СМо')
			and s.owner=23
			and s.date > '31.12.2014'
--			and dc.quantity>0
		GROUP BY s.type_doc, s.code, s.date, s.nn, s.c_to, ISNULL(reg1.id,0), s.dogovor, drp.rez_date
		)
	INSERT INTO [OLAP_DATA].[dbo].Orders_Fact
           ([date]
           ,[date_rez]
           ,[id]
           ,[nn]
           ,[type_doc]
           ,[managerID]
           ,[clientID]
           ,[regionID]
           ,[amount]
           ,[delivery]
           )
	SELECT
			[date]
		   ,[date_rez]
           ,[id]
           ,[nn]
           ,[type_doc]
           ,[managerID]
           ,[clientID]
           ,[regionID]
           ,[amount]
           ,[delivery]
	FROM trans