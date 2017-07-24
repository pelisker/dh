
	;WITH
	opers AS (
		SELECT oper=upcode, account=acck FROM uchet.dbo.oper (NOLOCK) GROUP BY upcode, acck HAVING SUM(CASE WHEN oper.acck IN ('021','03') THEN 1 ELSE 0 END)>0
		),
	vzv AS (SELECT pn.link, amount=-SUM(dc.amount) FROM uchet.dbo.doc_ref pn (NOLOCK)
		LEFT JOIN uchet.dbo.document dc (NOLOCK) ON pn.code=dc.upcode 
		WHERE pn.type_doc='П/Н+' AND dc.oper=513 GROUP BY pn.link
	),
	psr AS (SELECT psr.link, amount=SUM(dc.amount) FROM uchet.dbo.doc_ref psr (NOLOCK)
		LEFT JOIN uchet.dbo.document dc (NOLOCK) ON psr.code=dc.upcode 
		WHERE dc.oper=549 GROUP BY psr.link
	),
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
		FROM uchet.dbo.doc_ref s (NOLOCK)
		LEFT JOIN uchet.dbo.DrfDelivery drd (NOLOCK) ON s.code=drd.upcode
		LEFT JOIN uchet.dbo.DrfOrder dro (NOLOCK) ON dro.upcode=s.code
		LEFT JOIN uchet.dbo.DrfParam drp (NOLOCK) ON drp.upcode=s.code
		LEFT JOIN uchet.dbo.region reg (NOLOCK) ON ltrim(str(reg.code))=ltrim(rtrim(drd.ai_city)) OR (ISNULL(drd.ai_city,'')='' AND reg.code=1136)
		LEFT JOIN uchet.dbo.region reg_up1 (NOLOCK) ON reg_up1.code=reg.code
		WHERE
			s.type_doc IN ('СчМК','ЛИД','ЛИДА','СЧА','СМо2','СМо4','СМо6','СМо7')
			and s.owner=23
			and s.date > '31.12.2014'
		),
	trans AS (
		--Продажи
		SELECT
			[Дата РН]=rn.date
           ,[ID счета]=ISNULL(rn.link,0)
           ,[ID РН]=rn.code
           ,[Номер РН]=rn.nn
           ,[Юрик]=ISNULL(c_from.name,'')
           ,[Клиент РН]=ISNULL(c.name,'')
           ,[Клиенты папка РН]=ISNULL(c_up1.name,'')
           ,[Сумма РН]=sum(CASE WHEN dc.tovar!=6653 THEN dc.amount ELSE 0 END)+ISNULL(min(psr.amount),0)
           ,[Доставка РН]=sum(CASE WHEN dc.tovar=6653 THEN dc.amount ELSE 0 END)
           ,[Доставка факт РН]=ISNULL(MAX(drd.fact_amount),0)
           ,[Себестоимость доставки РН]=sum(CASE WHEN dc.tovar=6653 THEN ISNULL(dcp.am_cost,0) ELSE 0 END)
           ,[Возвраты РН]=ISNULL(sum(vzv.amount),0)
           ,[Способ доставки РН]=ISNULL(drd.ai_trcompany,'')
           ,[Трекинговый номер РН]=ISNULL(MAX(drd.ai_trID),'')
           ,drd.ai_city
		FROM uchet.dbo.doc_ref rn (NOLOCK)
		INNER JOIN uchet.dbo.document dc (NOLOCK) ON rn.code=dc.upcode
		INNER JOIN opers ON opers.oper=dc.oper
		LEFT JOIN uchet.dbo.docparam dcp (NOLOCK) ON dc.code=dcp.upcode
		LEFT JOIN vzv ON rn.link!=0 AND vzv.link=rn.link 
		LEFT JOIN psr ON rn.link!=0 AND psr.link=rn.link 
		LEFT JOIN uchet.dbo.DrfDelivery drd (NOLOCK) ON rn.code=drd.upcode
		LEFT JOIN uchet.dbo.DrfOrder dro (NOLOCK) ON dro.upcode=rn.code
		LEFT JOIN uchet.dbo.DrfParam drp (NOLOCK) ON drp.upcode=rn.code
		LEFT JOIN uchet.dbo.company c_from (NOLOCK) ON c_from.code=rn.c_from
		LEFT JOIN uchet.dbo.company c (NOLOCK) ON c.code=rn.c_to
		LEFT JOIN uchet.dbo.company c_up1 (NOLOCK) ON c_up1.code=c.upcode
		WHERE
			rn.type_doc!='П/Н+'
			and rn.owner=23
			and rn.date > '31.12.2014'
			and dc.quantity>0
			and dc.oper!=549
		GROUP BY rn.code, rn.date, rn.nn, rn.link, c_from.name,
		c.name, c_up1.name, c_up1.code,drd.ai_trcompany,drd.ai_trID, drd.ai_city
			
		)

	SELECT 
			--[Дата РН]
   --        ,[ID счета]
   --        ,[ID РН]
   --        ,[Номер РН]
   --        ,[Клиент РН]
   --        ,[Клиенты папка РН]
   --        ,[Сумма РН]
   --        ,[Доставка РН]
   --        ,[Доставка факт РН]
   --        ,[Себестоимость доставки РН]
   --        ,[Возвраты РН]
   --        ,[Способ доставки РН]
   --        ,[Трекинговый номер РН]
	Юрик,
	sum([Сумма РН])
	
	FROM trans
	
	where [Дата РН] between '01.07.16' and '30.06.17'
	and LTRIM(rtrim(isnull(ai_city,'')))='1146'
	group by Юрик


