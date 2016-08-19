
--with sales AS (SELECT c_to FROM doc_ref dr (NOLOCK)
--WHERE dr.type_doc LIKE '%Ð%Í%' GROUP BY c_to ORDER BY c_to, date desc)

--select c.code,
--	cmp.manager,
--man=sales.dogovor
----UPDATE cmp set manager=sales.dogovor
--from company c (NOLOCK)
--	inner join comparam cmp (NOLOCK)
--		on cmp.upcode=c.code
--	cross apply (SELECT top 1 dogovor FROM doc_ref dr (NOLOCK)
--WHERE dr.type_doc LIKE '%Ð%Í%' and dr.c_to=c.code ORDER BY date desc) AS sales
----	cross apply (SELECT top 1 dogovor FROM doc_ref dr (NOLOCK)
----WHERE dr.type_doc LIKE '%Ð%Í%' and dr.c_to=c.code ORDER BY date) AS sales2

--	--inner join doc_ref dr (NOLOCK)
--	--	ON dr.c_to=c.code
--	--left join dogovor d (nolock)
--	--	on d.code=dr.dogovor
--WHERE 
----dr.type_doc LIKE '%Ð%Í%' and 
--ISNULL(manager,0)=0
----order by code



--insert into comparam (upcode)
select --c.phone,
--UPDATE c set
--dop_info=ltrim(rtrim(c.dop_info))+' ['+ltrim(rtrim(c.phone))+']'
--phone=REPLACE(REPLACE(REPLACE(REPLACE(c.phone,'(',''),')',''),' ',''),'-','')
--,phone=left(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone,'(',''),')',''),' ',''),'-',''),'+7',''),10)

		c.code, c.name, c.company, phone, c.dop_info,inn, bank, bik=kod_mfo, kor_schet=acc1, schet=acc2, [address], manager=isnull(d.name,'')
		,city=isnull(sales.name,'')
      --,[persSurname]
      --,[persName]
      --,[persPatronymic]
      --,[persDate]
      --,[persGender]
      --,[persPhone]
      --,[persEmail]
      --,[compSite]
      --,[compContact]
      --,[compContactPost]
      --,[tags]
      --,[compType]
      --,[persCity]
      --,[utm_source]
      --,[utm_medium]
      --,[utm_term]
      --,[tell_activity]
      --,[utm_content]
      --,[utm_campaign]
      --,[referrer]
      

from company c (NOLOCK)
	left join comparam cmp (NOLOCK)
		on cmp.upcode=c.code
	left join dogovor d (NOLOCK)
		on d.code=cmp.manager
	outer apply (SELECT top 1 r.name FROM doc_ref dr (NOLOCK)
	inner join DrfDelivery drd (nolock) on dr.code=drd.upcode
	inner join region r (nolock) on cast(r.code AS varchar(10))=ltrim(rtrim(drd.ai_city))
WHERE dr.type_doc LIKE '%Ð%Í%' and dr.c_to=c.code ORDER BY date desc) AS sales

where 
--cmp.code is null and 
c.isgroup=1 and
c.upcode  IN (select code from company where code in (3,334,276,309,310,311,312,315))

--and LEN(c.phone)>10
--and LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone,'(',''),')',''),' ',''),'-',''),'+7',''))=7
--and (c.phone like '+7%')
--and len(REPLACE(REPLACE(REPLACE(REPLACE(LEFT(c.phone,CHARINDEX(';',c.phone)-1),'(',''),')',''),' ',''),'-','')) IN (11)
--order by c.code
