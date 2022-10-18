CREATE PROCEDURE [dbo].[fill_time_Dim]
AS
BEGIN

	SET DATEFORMAT dmy;
	SET LANGUAGE Russian

	declare @today date=getdate()
	truncate table time_dim

	insert into time_dim (date,[day],[month],[monthnum],[dayofweek],[dayofweeknum],[year])
	select --dateadd(mi, Минута, dateadd(hh, Час, CONVERT(datetime,День))) as Время,
		   convert(varchar(10),CONVERT(datetime,День),104) as День,
		   День as ДеньДляСортировки,
		   case datepart(mm,CONVERT(datetime,День))
			 when 1 then 'январь'
			 when 2 then 'февраль'
			 when 3 then 'март'
			 when 4 then 'апрель'
			 when 5 then 'май'
			 when 6 then 'июнь'
			 when 7 then 'июль'
			 when 8 then 'август'
			 when 9 then 'сентябрь'
			 when 10 then 'октябрь'
			 when 11 then 'ноябрь'
			 when 12 then 'декабрь'
		   end Месяц,
		   datepart(mm,CONVERT(datetime,День)) as МесяцДляСортировки,
		   lower(datename(weekday,CONVERT(datetime,День))) as ДеньНедели,
		   case lower(datename(weekday,CONVERT(datetime,День)))
			 when 'понедельник'    then 1
			 when 'вторник'   then 2
			 when 'среда' then 3
			 when 'четверг'  then 4
			 when 'пятница'    then 5
			 when 'суббота'  then 6
			 when 'воскресенье'    then 7
		   end as ДеньНеделиДляСортировки,
		   datepart(yy,CONVERT(datetime,День)) as Год

		   --right('0'+convert(varchar(2),Час),2)+':'+ right('0'+convert(varchar(2),Минута),2) as Минута,
		   --right('0'+convert(varchar(2),Час),2)+':00' as Час,
		   --case
		   --  when right('0'+convert(varchar(2),Час),2)+':'+ right('0'+convert(varchar(2),Минута),2) between '00:00' and '08:59' then 'от 00:00 до 09:00'
		   --  when right('0'+convert(varchar(2),Час),2)+':'+ right('0'+convert(varchar(2),Минута),2) between '09:00' and '18:59' then 'от 09:00 до 19:00'
		   --  else 'от 19:00 до 00:00'
		   --end as Период
	  from (-- дни
			select 40177 + (ROW_NUMBER() over(ORDER BY v1.number)-1) as День from master.dbo.spt_values v1 full join (SELECT code=1 UNION SELECT code=2 UNION SELECT code=3) v2 on 1=1
		   ) as t1
	  --cross join (-- часы
	  --            select top 24 ROW_NUMBER() over(ORDER BY number)-1 as Час from master.dbo.spt_values
	  --           ) as t2
	  --cross join (--минуты
	  --            select top 60 ROW_NUMBER() over(ORDER BY number)-1 as Минута from master.dbo.spt_values
	  --           ) as t3
	  where CONVERT(datetime,День) >= '20140101' and
			CONVERT(datetime,День) <= DATEADD(year,1,getdate())

	truncate table times_dim

	insert into times_dim (id, [date], [dateName], [day],[week],[month],[monthnum],[dayofweek],[dayofweeknum],[year],[diffDay])
	select 
		   id=datepart(YEAR,CONVERT(datetime,День))*10000 + datepart(M,CONVERT(datetime,День))*100 + datepart(D,CONVERT(datetime,День)),
		   [date] = convert(varchar(10),CONVERT(datetime,День),104),
		   [datename]= convert(varchar(8),CONVERT(datetime,День),4),
		   [day] = День,
		   Неделя = datepart(WEEK,CONVERT(datetime,День)),
		   case datepart(mm,CONVERT(datetime,День))
			 when 1 then 'январь'
			 when 2 then 'февраль'
			 when 3 then 'март'
			 when 4 then 'апрель'
			 when 5 then 'май'
			 when 6 then 'июнь'
			 when 7 then 'июль'
			 when 8 then 'август'
			 when 9 then 'сентябрь'
			 when 10 then 'октябрь'
			 when 11 then 'ноябрь'
			 when 12 then 'декабрь'
		   end Месяц,
		   МесяцДляСортировки = datepart(mm,CONVERT(datetime,День)),
		   ДеньНедели = lower(datename(weekday,CONVERT(datetime,День))),
		   case lower(datename(weekday,CONVERT(datetime,День)))
			 when 'понедельник'    then 1
			 when 'вторник'   then 2
			 when 'среда' then 3
			 when 'четверг'  then 4
			 when 'пятница'    then 5
			 when 'суббота'  then 6
			 when 'воскресенье'    then 7
		   end as ДеньНеделиДляСортировки,
		   datepart(yy,CONVERT(datetime,День)) as Год,
		   DATEDIFF(dd,CONVERT(datetime,День),@today)

	  from (-- дни
			select 40177 + (ROW_NUMBER() over(ORDER BY v1.number)-1) as День from master.dbo.spt_values v1 full join (SELECT code=1 UNION SELECT code=2 UNION SELECT code=3) v2 on 1=1
		   ) as t1
	  where CONVERT(datetime,День) >= '20130101' and
			CONVERT(datetime,День) <=  DATEADD(year,1,getdate()) --getdate()+100       
END