select * from doc_ref a inner join doc_ref b on a.link=b.code where a.type_doc like '%Ð%' and b.type_doc like '%Ð%'
select * from doc_ref where type_doc like '%%'


select * from columns


select * from doc_ref where code=797997
select * from doc_ref where code=

select * from  where code=798430
select * from doc_ref where code=798429
### 5%
select * from doc_ref where code=798430

select (case when CHARINDEX('%',a.name)<>0 then ABS(a.total)*100/convert(int,rtrim(ltrim(SUBSTRING(a.name,charindex('%',a.name)-2,2)))) else 0 end) totalpsr,a.code,a.nn,a.date, a.total,a.name,a.type_doc,b.nn nnrn,b.date drn,b.total totalrn,b.name namern,b.amount amountrn,b.type_doc tdrn into #temp from doc_ref a 
 inner join (select dr.code,dr.nn,dr.date,dr.total,dr.name,dr.type_doc ,dr.link,SUM(amount) amount  from doc_ref dr inner join document dc on dr.code=dc.upcode inner join nomencl n on dc.tovar=n.code where dr.type_doc like '%Ð/Í+%' and n.upcode<>19350 group by dr.code,dr.nn,dr.date,dr.total,dr.name,dr.type_doc,dr.link) b on a.link=b.link  where a.type_doc like '%ÏÑÐ%' /*a.code=798422*/ and   b.type_doc like '%Ð/Í+%' and a.link<>0 and b.link<>0  order by a.code
 
 
 select * from #temp where totalpsr<>amountrn