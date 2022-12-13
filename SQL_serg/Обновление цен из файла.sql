--drop table _price
with c AS (

select code=[Код], price04=p.[ЦЕНА розница], price05 = p.[ ЦЕНА по акции] from _price p
)
--update n set  n.price04=c.price04 , n.price05 = c.price05 from nomencl n inner join c on n.code=c.code
