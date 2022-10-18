


--Заполнение таблицы фактов для PowerBI

CREATE PROCEDURE [external].[fill_PBI_sales]

AS

SET DATEFORMAT dmy;
	TRUNCATE TABLE [external].[PBI_sales]
	;WITH
	opers AS (
		SELECT oper=upcode, account=acck FROM uchet.dbo.oper (NOLOCK) GROUP BY upcode, acck HAVING SUM(CASE WHEN oper.acck IN ('021','03') THEN 1 ELSE 0 END)>0
		),
	vzv AS (SELECT pn.link, amount=-SUM(dc.amount) FROM uchet.dbo.doc_ref pn (NOLOCK)
		LEFT JOIN uchet.dbo.document dc (NOLOCK) ON pn.code=dc.upcode 
		WHERE pn.type_doc='П/Н+' AND dc.oper=513 AND pn.link!=0
		GROUP BY pn.link
	),
	payments AS (SELECT dr.link, pay_type=CASE min(ord) WHEN 1 THEN 'Безнал' WHEN 2 THEN 'Карта' WHEN 3 THEN 'Нал' WHEN 4 THEN 'НП' ELSE '' END
		FROM uchet.dbo.doc_ref dr (NOLOCK)
			LEFT JOIN uchet.dbo.document dc (NOLOCK) 
				ON dr.code=dc.upcode 
			INNER JOIN (SELECT 1 AS ord, 545 code UNION ALL SELECT 2 AS ord, 518 code UNION ALL SELECT 3 AS ord, 80 code UNION ALL SELECT 4 AS ord, 552 code) AS oper
				ON dc.oper=oper.code
			WHERE dc.oper IN (518,80,545,552) AND dr.link!=0
		GROUP BY dr.link
	),

	--schet AS (SELECT s.code
	--		FROM uchet.dbo.doc_ref s (NOLOCK)
	--		WHERE
	--		s.type_doc IN ('СчМК','ЛИД','ЛИДА','СЧА','СМо2','СМо4','СМо6','СМо7')
	--		and s.owner=23
	--		and s.date > '31.12.2014'
	--		GROUP BY
	--),
	orders AS (
		--Продажи
		SELECT
           [id]=s.code
           ,nn=s.nn
           ,[date_rez]=CASE WHEN drp.rez_date='1900-01-01' THEN s.date ELSE ISNULL(drp.rez_date,s.date) END
           ,[utm]=REPLACE(ISNULL(dro.UtmSource,''),' ','')+' '+REPLACE(ISNULL(dro.UtmMedium,''),' ','')
           ,[region]=ISNULL(reg.name,'')
           ,[region_up1]=ISNULL(reg_up1.name,'')
		   ,[delivery_fact]=ISNULL(drd.fact_amount,0)
		   ,TK=ISNULL(drd.ai_trcompany,'')
		   ,ai_trID=ISNULL(drd.ai_trID,'')
		   ,volOur=ISNULL(dro.volOur,0)
		   ,wtOur=ISNULL(dro.wtOur,0)
		   ,volTK=ISNULL(dro.volTK,0)
		   ,wtTK=ISNULL(dro.wtTK,0)
		   ,[client]=ISNULL(c.name,'')		   		   
           ,[client_up1]=ISNULL(c_up1.name,'')
           ,client_type=CASE ISNULL(c.nick,'') WHEN 'ОПТ' THEN 'ОПТ' WHEN 'ПСР' THEN 'ПСР' WHEN 'ДИЛЕР' THEN 'ДИЛЕР' ELSE 'РОЗ' END
           ,[source]=CASE WHEN c_up1.code IN (276,311,312,309,310,315) THEN 'Интернет' 
				WHEN c_up1.code IN (3,331,332,390) THEN 'Магазины' 
				WHEN c_up1.code IN (334,345,346,347,500) THEN 'Опт' 
				WHEN c_up1.code IN (370) THEN 'Клиенты СПБ' 
				WHEN c_up1.code IN (368) THEN 'Армада' 
				WHEN c_up1.code IN (367) THEN 'Артплей' 
				WHEN c_up1.code IN (301) THEN 'Гранд'
				WHEN c_up1.code IN (371) THEN 'Краснодар'
				WHEN c_up1.code IN (372) THEN 'Нижний Новгород'
				WHEN c_up1.code IN (373) THEN 'Казань'
				WHEN c_up1.code IN (374) THEN 'Екатеринбург'
				WHEN c_up1.code IN (382) THEN 'Краснодар2'
				WHEN c_up1.code IN (377) THEN 'Новосибирск'
				WHEN c_up1.code IN (376) THEN 'Сочи'
				WHEN c_up1.code IN (193) THEN 'Румер'
					ELSE 'Неопределен' END
		FROM uchet.dbo.doc_ref s (NOLOCK)
		LEFT JOIN uchet.dbo.DrfDelivery drd (NOLOCK) ON s.code=drd.upcode
		LEFT JOIN uchet.dbo.DrfOrder dro (NOLOCK) ON dro.upcode=s.code
		LEFT JOIN uchet.dbo.DrfParam drp (NOLOCK) ON drp.upcode=s.code
		LEFT JOIN uchet.dbo.region reg (NOLOCK) ON ltrim(str(reg.code))=ltrim(rtrim(drd.ai_city)) OR (ISNULL(drd.ai_city,'')='' AND reg.code=1136)
		LEFT JOIN uchet.dbo.region reg_up1 (NOLOCK) ON reg_up1.code=reg.code
		LEFT JOIN uchet.dbo.company c (NOLOCK) ON c.code=s.c_to
		LEFT JOIN uchet.dbo.company c_up1 (NOLOCK) ON c_up1.code=c.upcode
		WHERE
			s.type_doc IN ('СчМК','ЛИД','ЛИДА','СЧА','СМо1','СМо2','СМо3','СМо4','СМо5','СМо6','СМо7','СМо8','СМо9','СМо')
			and (s.code=s.link or s.link=0)
			and s.owner=23
			and s.date > '31.12.2014'
		UNION ALL
		SELECT 
		   [id]=0
           ,nn='Нет'
           ,[date_rez]='1900-01-01'
           ,[utm]=''
           ,[region]=''
           ,[region_up1]=''
		   ,[delivery_fact]=0
		   ,TK=''
		   ,ai_trID=''
		   ,volOur=0
		   ,wtOur=0
		   ,volTK=0
		   ,wtTK=0
   		   ,[client]=''
           ,[client_up1]=''
   		   ,client_type=''
           ,[source]=''

		),
	trans AS (
		--Продажи
		SELECT
           [date]=min(rn.date)
           ,[date_rez]=ISNULL(ord.date_rez,MIN(rn.date))
           ,[id]=0 --rn.code
           ,OrderId=ISNULL(ord.id,0)
           ,[nn]=''
           ,nn_sch=ISNULL(ord.nn,'')
           ,[client]=ISNULL(ord.client,'')
           ,[client_up1]=ISNULL(ord.client_up1,'')
           ,client_type=ISNULL(ord.client_type,'')
           ,[source]=ISNULL(ord.source,'')
           ,[region]=ISNULL(ord.region,'')
           ,[region_up1]=ISNULL([region_up1],'')
           ,TK=ISNULL(ord.TK,'')
           ,pay_type=ISNULL(pay.pay_type,'')
		   ,[utm]=ISNULL([utm],'')
           ,[amount]=sum(CASE WHEN dc.tovar!=6653 THEN dc.amount ELSE 0 END)
		   ,[delivery]=sum(CASE WHEN dc.tovar=6653 THEN dc.amount ELSE 0 END)
		   ,[return]=ISNULL(max(vzv.amount),0)
		   ,[amountwithoutreturn]=sum(CASE WHEN dc.tovar!=6653 THEN dc.amount ELSE 0 END)-ISNULL(max(vzv.amount),0)
		   ,[sebest_delivery]=sum(CASE WHEN dc.tovar=6653 THEN ISNULL(dcp.am_cost,0) ELSE 0 END)
		   ,[delivery_fact]=ISNULL(MAX(ord.delivery_fact),0)
		   ,ai_trID=ISNULL(MAX(ord.ai_trID),'')
		   ,volOur=ISNULL(MAX(ord.volOur),0)
		   ,wtOur=ISNULL(MAX(ord.wtOur),0)
		   ,volTK=ISNULL(MAX(ord.volTK),0)
		   ,wtTK=ISNULL(MAX(ord.wtTK),0)		   		   
		FROM uchet.dbo.doc_ref rn (NOLOCK)
		INNER JOIN uchet.dbo.document dc (NOLOCK) ON rn.code=dc.upcode
		INNER JOIN opers ON opers.oper=dc.oper
		LEFT JOIN uchet.dbo.docparam dcp (NOLOCK) ON dc.code=dcp.upcode
		LEFT JOIN vzv ON rn.link!=0 AND vzv.link=rn.link 
		INNER JOIN orders ord ON ord.id=rn.link --AND rn.link!=0
		LEFT JOIN payments pay ON ord.id=pay.link
		--OR (ISNULL(drd.ai_city,'')='' AND reg1.NameL3='Москва'
		
		--(SELECT id=max(id), nameL3 FROM Region_Dim GROUP BY nameL3) reg1 
		--	ON ltrim(str(reg1.id))=ltrim(rtrim(drd.ai_city))
		--		OR (ISNULL(drd.ai_city,'')='' AND reg1.NameL3='Москва' )
		WHERE
			rn.type_doc!='П/Н+'
			and rn.owner=23
			and rn.date > '31.12.2014'
			and dc.quantity>0
		GROUP BY --rn.date, 
		ISNULL(ord.id,0), 
		ord.nn, ord.region, ord.region_up1, [date_rez], utm, ord.TK, [client], client_type ,[client_up1],[source], pay_type
		)
	INSERT INTO [OLAP_DATA].[external].PBI_sales
           (	
            [Дата],
			[Дата резерва],
			[ID заказа],
			[ID счета],
			[Номер],
			[Номер счета],
			[Клиент],
			[Тип клиента],
			[Клиенты папка],
			[Способ оплаты],
			[Источник],
			[Город],
			[Область],
			[utm],
			[Способ доставки],
			[Сумма заказа],
			[Доставка],
			[Доставка факт],
			[Себестоимость доставки],
			[Возвраты],
			[Сумма минус возвраты],
			[Объем ТК],
			[Вес ТК],
			[Объем],
			[Вес],
			[Трекинговый номер]
           )

		
	SELECT
			[date]
		   ,[date_rez]
           ,[id]
           ,[OrderId]
           ,[nn]
           ,[nn_sch]
           ,[client]
           ,[client_type]
           ,[client_up1]
           ,[pay_type]
           ,[source]
           ,[region]
           ,[region_up1]
           ,[utm]
           ,TK
           ,[amount]
           ,[delivery]
           ,[delivery_fact]
           ,[sebest_delivery]
           ,[return]
           ,[amountwithoutreturn]
           ,[volTK]
           ,[wtTK]
           ,[volOur]
           ,[wtOur]
           ,ai_trID
	FROM trans order by date desc