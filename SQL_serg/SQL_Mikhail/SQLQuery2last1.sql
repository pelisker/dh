--select * from doc_ref a inner join doc_ref b on a.link=b.code where a.type_doc like '%Ð%' and b.type_doc like '%Ð%'
--select * from doc_ref where type_doc like '%%'


--select * from columns


--select * from doc_ref where code=797997
--- * from doc_ref where code=

--select * from  where code=798430
--select * from doc_ref where code=798429
--### 5%
--select * from doc_ref where code=798430
--exec ad_PSR_report_f1412_1 '01.05.2018','01.09.2018'
alter procedure ad_PSR_report_f1412_1
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
         WHERE  dr.type_doc LIKE 'Ð%Í%' 
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
         WHERE  a.type_doc LIKE '%ÏÑÐ%' /*a.code=798422*/ 
                
                AND a.link <> 0 
                AND rn.link <> 0 
         /*ORDER  BY a.code*/), 
         
         
          pn 
     AS (SELECT dr.link, 
                Sum(amount) amount 
         FROM   doc_ref dr 
                INNER JOIN document dc 
                        ON dr.code = dc.upcode 
                INNER JOIN nomencl n 
                        ON dc.tovar = n.code 
         WHERE  dr.type_doc LIKE 'Ï%Í%' 
                AND n.upcode <> 19350 
         GROUP  BY dr.link),
         psr1 
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
                 
                pn.amount   amountpn 
                 
         FROM   doc_ref a 
                INNER JOIN pn 
                        ON a.link = pn.link 
         WHERE  a.type_doc LIKE '%ÏÑÐ%' /*a.code=798422*/ 
                
                AND a.link <> 0 
                AND pn.link <> 0 
         /*ORDER  BY a.code*/)
        
         
         
SELECT * 
FROM   psr 
WHERE  totalpsr <> amountrn 
       AND ( date BETWEEN @date1 AND @date2 ) 
       
       
   union all
   
   SELECT * 
FROM   psr1 
WHERE  totalpsr <> amountpn 
       AND ( date BETWEEN @date1 AND @date2 )     
 end