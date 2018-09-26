use uchet
declare @tovar int=50457
--exec [dbo].[_CheckTovarOstat] @tovar
select * from ostatq where tovar=@tovar --and account='29'
select * from ostatq_hist where tovar=@tovar and account='29'

--select * from formula where name like '%пересчет%'

