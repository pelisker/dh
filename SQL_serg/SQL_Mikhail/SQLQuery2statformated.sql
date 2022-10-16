WITH stat 
     AS (SELECT dr.c_to, 
                mindate=Min(dr.date), 
                maxdate=Max(date), 
                sales=Count(*) 
         FROM   doc_ref dr (nolock) 
         WHERE  dr.type_doc LIKE 'СМо%' 
         GROUP  BY dr.c_to), 
     period 
     AS (SELECT c_to, 
                sales, 
                avgperiod=Cast(Datediff(m, mindate, maxdate)AS MONEY) / sales, 
                lastsaleperiod=Cast(Datediff(m, maxdate, Getdate())AS MONEY) 
         FROM   stat), 
     nom1 
     AS (SELECT DISTINCT nl.code AS codenl, 
                         nl.NAME namenl, 
                         c1.code, 
                         c1.NAME, 
                         c1.upcode 
         FROM   nomencl nl 
                INNER JOIN class c 
                        ON nl.upcode = c.code 
                INNER JOIN class c1 
                        ON c.upcode = c1.code 
         WHERE  c1.upcode = 5120), 
     drf1 
     AS (SELECT drf.type_doc, 
                drf.code, 
                drf.c_to, 
                drf.date, 
                dc.code AS code1, 
                dc.tovar 
         FROM   doc_ref drf 
                INNER JOIN document dc 
                        ON drf.code = dc.upcode 
         WHERE  drf.type_doc LIKE 'СМо%'), 
     drfnom 
     AS (SELECT drf1.type_doc, 
                drf1.code, 
                drf1.c_to, 
                drf1.date 
         FROM   drf1 
                INNER JOIN nom1 
                        ON drf1.tovar = nom1.codenl), 
     stat1 
     AS (SELECT dr.c_to, 
                mindate=Min(dr.date), 
                maxdate=Max(dr.date), 
                sales=Count(*) 
         FROM   drfnom dr (nolock) 
         WHERE  dr.type_doc LIKE 'СМо%' 
         GROUP  BY dr.c_to), 
     period1 
     AS (SELECT c_to, 
                sales, 
                avgperiod=Cast(Datediff(m, mindate, maxdate)AS MONEY) / sales, 
                lastsaleperiod=Cast(Datediff(m, maxdate, Getdate())AS MONEY) 
         FROM   stat1) 
SELECT * 
FROM   period1 
WHERE  avgperiod > 0 
       AND lastsaleperiod > avgperiod * 2 
-- оставить только клиентов которые покупали мебель 