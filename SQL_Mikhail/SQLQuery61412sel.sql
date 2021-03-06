USE [uchet]
GO
/****** Object:  StoredProcedure [dbo].[ad_PSR_report_f1412]    Script Date: 09/20/2018 12:31:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from doc_ref a inner join doc_ref b on a.link=b.code where a.type_doc like '%Р%' and b.type_doc like '%Р%'
--select * from doc_ref where type_doc like '%%'


--select * from columns


--select * from doc_ref where code=797997
--- * from doc_ref where code=

--select * from  where code=798430
--select * from doc_ref where code=798429
--### 5%
--select * from doc_ref where code=798430
--exec ad_GetPSR '01.08.2018','01.09.2018'
ALTER procedure [dbo].[ad_PSR_report_f1412]
@date1 datetime,
@date2 datetime
as
begin

WITH rn 
     AS (SELECT dr.link, 
                Sum(amount) amount 
         FROM   doc_ref dr 
                INNER JOIN document dc 
                        ON dr.code = dc.upcode 
                INNER JOIN nomencl n 
                        ON dc.tovar = n.code 
         WHERE  dr.type_doc LIKE 'Р%Н%' 
                AND n.upcode <> 19350 
         GROUP  BY dr.link), 
     psr 
     AS (SELECT ( CASE 
                    WHEN Charindex('%', a.NAME) <> 0 THEN Abs(a.total) * 100 / 
                    CONVERT(INT, Rtrim(Ltrim( 
                    Substring(a.NAME, 
                    Charindex('%', a.NAME) 
                    - 2, 2)))) 
                    ELSE 0 
                  END )    totalpsr, 
                a.code, 
                a.nn, 
                a.date, 
                a.total, 
                a.NAME, 
                a.type_doc, 
                 
                rn.amount   amountrn 
                 
         FROM   doc_ref a 
                INNER JOIN rn 
                        ON a.link = rn.link 
         WHERE  a.type_doc LIKE '%ПСР%' /*a.code=798422*/ 
                
                AND a.link <> 0 
                AND rn.link <> 0 
         /*ORDER  BY a.code*/) 
SELECT * 
FROM   psr 
WHERE  totalpsr <> amountrn 
       AND ( date BETWEEN @date1 AND @date2 ) 
 end