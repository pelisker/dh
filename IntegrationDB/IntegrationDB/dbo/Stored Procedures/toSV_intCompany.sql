
-- =============================================
-- Author:		SCH
-- Create date: 02.06.2016
-- Description:	Загрузка анкет клиентов с сайта
-- =============================================
CREATE PROCEDURE [dbo].[toSV_intCompany]

AS

BEGIN

	SET NOCOUNT ON;
	DECLARE @id int,
	@company int
	
	DECLARE @codes table (code int)

	SELECT top 1 
		@id=c.code
	FROM intCompany c
	WHERE c.sv=0 ORDER BY date
	
	IF @id IS NULL
		RETURN 0

	--Что делать если клиент уже существует?
		
	----Если клиент не найден по ID, то ищется по номеру телефона.		
	--IF @clientID IS NULL
	--BEGIN
	--	SELECT 
	--		@clientID=c.code 
	--	FROM 
	--		uchet.dbo.company c (NOLOCK) 
	--	WHERE
	--		--c.upcode IN (SELECT code FROM uchet.dbo.company (NOLOCK) WHERE upcode=276) AND 
	--		LEFT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone,'.','') ,':','') ,'тел','') ,' ','') ,')','') ,'(','') ,'-',''),'+7',''),10)=@phoneNumber
	--		OR 
	--		LEFT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.phone,'.','') ,':','') ,'тел','') ,' ','') ,')','') ,'(','') ,'-',''),'+7',''),10)=@phoneNumber2
	--		OR
	--		c.email=@email
	--		OR
	--		c.email=@email2
	--	--Если клиент найден по телефону, то привязывается к клиенту в справочнике.
	--	IF @clientID IS NOT NULL
	--	BEGIN
	--		UPDATE uchet.dbo.comparam SET intCode=@intClient WHERE upcode=@clientID
	--		IF @@ROWCOUNT=0
	--			INSERT INTO uchet.dbo.comparam (upcode,intCode) VALUES (@clientID,@intClient)
	--		UPDATE [Integration].[dbo].intClient
	--			SET sv=1
	--		WHERE 
	--			code=@intClient
	--	END
	--END
	
	--Если клиент не найден, то создается новый
	
	--Поиск пустого кода. Чтобы закрыть дырки в кодах.
	;with numbers AS (
		select code=10000+ROW_NUMBER() over (ORDER BY n1)
		from 
			(select top 500 n1=number from master.dbo.spt_values) v1 
		full join 
			(select top 300 n2=number from master.dbo.spt_values) v2 on 1=1)
	select TOP 1 @company=n.code 
	from numbers n
	LEFT JOIN uchet.dbo.company c (NOLOCK) ON n.code=c.code
	WHERE ISNULL(c.code,0)=0
	ORDER BY n.code	
	
	IF @company IS NULL
		RETURN -1
	
	exec uchet.dbo.InitProcess 555,0

	SET IDENTITY_INSERT uchet.dbo.company ON
	
	INSERT INTO uchet.dbo.company (code,upcode,name,company,phone)
	--OUTPUT inserted.code INTO @codes
	SELECT 
		code=@company,
		upcode=345, 
		name='[Анкета]'+CASE WHEN ISNULL(c.compName,'')='' THEN 
				CASE WHEN ISNULL(c.persSurname+' '+c.persName+' '+c.persPatronymic,'')='' THEN ISNULL(c.persSurname+' '+c.persName+' '+c.persPatronymic,'') 
				ELSE cast(@id AS varchar(10)) END
			ELSE c.compName END,
		company=c.compName,
		phone=REPLACE(REPLACE(REPLACE(REPLACE(c.compPhone,'(',''),')',''),'-',''),' ','')
	FROM intCompany c
	WHERE c.code=@id

	SET IDENTITY_INSERT uchet.dbo.company OFF
--persName
--persSurname
--persPhone
--persEmail
--persCity
--compName

	--Заполнение доп. параметров	
	--SET @company=(SELECT max(code) FROM @codes)
	IF NOT EXISTS(SELECT code FROM uchet.dbo.comparam WHERE upcode=@company)
		INSERT INTO uchet.dbo.comparam (upcode) VALUES (@company)

	UPDATE cmp SET persName=c.persName, manager=c.manager, persSurname=c.persSurname, persEmail=c.persEmail, persPhone=REPLACE(REPLACE(REPLACE(REPLACE(c.persPhone,'(',''),')',''),'-',''),' ',''),
		persDate=c.persDate, persGender=c.persGender, persPatronymic=c.persPatronymic, compContact=c.compContact,
		compContactPost=c.compContactPost, compSite=c.compSite, compType=c.compType, tags=c.tags, utm_medium=c.utm_medium,
		utm_source=c.utm_source, utm_term=c.utm_term, tell_activity=c.tell_activity
	FROM
		uchet.dbo.comparam cmp
	INNER JOIN
		intCompany c 
			ON cmp.upcode=@company AND c.code=@id
	
	
	--DELETE FROM @codes
	--UPDATE [Integration].[dbo].intClient
	--	SET sv=1
	--WHERE 
	--	code=@intClient
	
	UPDATE intCompany SET sv=1 WHERE code=@id

END

