with stat AS (
SELECT 
	dr.c_to,
	mindate=min(dr.date), maxdate=MAX(date), sales=COUNT(*)
FROM
	doc_ref dr (NOLOCK)
WHERE dr.type_doc LIKE 'СМо%'
GROUP BY dr.c_to),
period AS (
SELECT c_to, sales, avgperiod=cast(DATEDIFF(m, mindate, maxdate)AS money)/sales, lastsaleperiod=cast(DATEDIFF(m, maxdate, GETDATE())AS money) FROM stat),

 nom1 as
(
select distinct nl.code as codenl,nl.name namenl,c1.code,c1.name,c1.upcode from nomencl nl inner join class c on nl.upcode=c.code
inner join class c1 on c.upcode=c1.code where c1.upcode=5120
),
drf1 as
(
select drf.type_doc,drf.code,drf.c_to,drf.date,dc.code as code1,dc.tovar from doc_ref drf inner join document dc on drf.code=dc.upcode where drf.type_doc LIKE 'СМо%'
),
drfnom as
(
select drf1.type_doc,drf1.code,drf1.c_to,drf1.date from drf1 inner join nom1 on drf1.tovar=nom1.codenl

)
,

 stat1 AS (
SELECT 
	dr.c_to,
	mindate=min(dr.date), maxdate=MAX(dr.date), sales=COUNT(*)
FROM
	drfnom dr (NOLOCK)
WHERE dr.type_doc LIKE 'СМо%'
GROUP BY dr.c_to),
period1 AS (
SELECT c_to, sales, avgperiod=cast(DATEDIFF(m, mindate, maxdate)AS money)/sales, lastsaleperiod=cast(DATEDIFF(m, maxdate, GETDATE())AS money) FROM stat1)


SELECT * FROM period1 WHERE avgperiod>0 and lastsaleperiod>avgperiod*2

-- оставить только клиентов которые покупали мебель
