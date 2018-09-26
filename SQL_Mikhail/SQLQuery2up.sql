

--exec ad_PSR_report_f1412_up '01.05.2018','01.09.2018'

 alter procedure [dbo].[ad_PSR_report_f1412_up]
@date1 datetime,
@date2 datetime

as
begin
  
 exec dbo.InitProcess 555,0;
  
  
  WITH rn1 
     AS (SELECT dr.link,MAX(dr.date) date1, 
                Sum(amount) amount 
         FROM   doc_ref dr 
                INNER JOIN document dc 
                        ON dr.code = dc.upcode 
                INNER JOIN nomencl n 
                        ON dc.tovar = n.code 
         WHERE  dr.type_doc LIKE 'Ð%Í%' 
                AND n.upcode <> 19350 
         GROUP  BY dr.link),
         
     psr2 
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
                rn1.date1,
                
             rn1.amount   amountrn ,
             (case when (DATEPART(m,a.date)=DATEPART(M,rn1.date1) and DATEPART(d,a.date)<>DATEPART(d,rn1.date1)) /*OR (DATEPART(y,a.date)<>DATEPART(y,rn1.date1))*/ then 1 else 0 end) OtherDay
                 
         FROM   doc_ref a 
                INNER JOIN rn1 
                        ON a.link = rn1.link 
         WHERE  a.type_doc LIKE '%ÏÑÐ%' /*a.code=798422*/ 
                
                AND a.link <> 0 
                AND rn1.link <> 0 and
                a.date BETWEEN @date1 AND @date2 ) 
              
             -- select * from psr2 where OtherDay=1
                 
           update doc_ref set date=b.date1,mark=1  from doc_ref a inner join
           (select code,date,date1 from psr2 where OtherDay=1) b on a.code=b.code
                   
        end