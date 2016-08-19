
declare @upcode int=301

--select phoneID, dbo.parse_phone(phoneID),LEN(dbo.parse_phone(phoneID))
--FROM company c 
--INNER JOIN comparam cmp
--ON c.code=cmp.upcode
--where c.upcode in (@upcode)
----and (phoneID LIKE '89%' OR REPLACE(phoneID,'+7','7') LIKE '79%')

select distinct LEN(dbo.parse_phone2(phone)), count(*)
FROM company c 
--INNER JOIN comparam cmp
--ON c.code=cmp.upcode
--where c.upcode in (@upcode)
--where (phone LIKE '%,%' 
--OR phone LIKE '%;%')
group by LEN(dbo.parse_phone2(phone))
order by 1

INSERT INTO comphone (upcode,code,phoneID) 
select 
distinct c.code,p.num,
p.phone
FROM company c 
cross apply
dbo.parse_phone(c.phone) p
--INNER JOIN comparam cmp
--ON c.code=cmp.upcode
where LEN(dbo.parse_phone2(c.phone)) IN (7,10,11,14,18,22)
order by 1


--select * from comphone

--phone like '% %'
----1.Перенос телефона в comparam
--INSERT INTO comparam (upcode)
--SELECT c.code
--FROM company c 
--LEFT JOIN comparam cmp
--ON c.code=cmp.upcode
--where c.upcode in (@upcode) AND cmp.code IS NULL

--update cmp
--set phoneID=ISNULL(LEFT(phone,50),'')
--FROM company c 
--INNER JOIN comparam cmp
--ON c.code=cmp.upcode
--where c.upcode in (@upcode)


----2.
--update cmp
--set phoneID=phoneID
--FROM company c 
--INNER JOIN comparam cmp
--ON c.code=cmp.upcode
--where c.upcode in (@upcode)


--and 
--phone like '% %'


--declare @pn varchar(100)= '8(495)150-05-59, 8(916)683-89-63'
--,@ch char, @i int=1
--,@norm varchar(100)=''
--WHILE @i<=LEN(@pn)
--BEGIN
--	SET @ch=SUBSTRING(@pn,@i,1)
--	IF @ch LIKE '[0123456789]'
--		SET @norm=@norm+@ch
--	SET @i=@i+1
--END
--SELECT LEN(@norm), @norm