USE uchet
GO
/****** Object:  StoredProcedure [dbo].[toSV_intCompany]    Script Date: 08/30/2016 15:24:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		SCH
-- Create date: 02.06.2016
-- Description:	�������� ����� �������� � �����
-- =============================================
CREATE PROCEDURE [dbo].[ad_setClient]
	@amoID int,
	@intID int,
	@comagicID int,
	@type varchar(10),/*������,���,�������*/
	@name char(80),
	@fullname varchar(250),
	@inn char(20),
	@kpp varchar(20),
	@bank varchar(600),
	@bik char(15),
	@acc1 char(20),
	@acc2 char(20),
	@phone varchar(150),
	@email varchar(100),
	@address varchar(500),
	@region varchar(200),
	@RealAddres varchar(500),
	@manager varchar(50),
	@compSite varchar(100),
	@compContact varchar(150),
	@compContactPost varchar(50),
	@tags varchar(2000),
	@compType tinyint,
	@persSurname varchar(50),
	@persName varchar(50),
	@persPatronymic varchar(50),
	@persDate smalldatetime,
	@persGender tinyint,
	@persPhone varchar(50),
	@persEmail varchar(100),
	@persCity varchar(100)
AS

BEGIN

	SET NOCOUNT ON;
	DECLARE @companyID int, @regionID int, @managerID int
	DECLARE @codes table (code int)

	IF @amoID IS NULL
		RETURN 0

	--����� �������
	SET @regionID=ISNULL(
		(SELECT code 
			FROM region 
			WHERE name=ltrim(rtrim(@region))),0)			
	
	--����� ���������
	SET @managerID=ISNULL(
		(SELECT code 
			FROM dogovor 
			WHERE name=ltrim(rtrim(@manager))),0)
			
	--������������ ��������
	SET @phone=REPLACE(REPLACE(REPLACE(REPLACE(@phone,'(',''),')',''),'-',''),' ','')

	SET @companyID=(SELECT c.code FROM company c (NOLOCK) INNER JOIN comparam cmp (NOLOCK) ON c.code=cmp.upcode WHERE cmp.amoID=@amoID)
	
	IF @companyID IS NOT NULL
	BEGIN 
		--���������� ���. ����������	
		IF NOT EXISTS(SELECT code FROM uchet.dbo.comparam WHERE upcode=@companyID)
			INSERT INTO uchet.dbo.comparam (upcode) VALUES (@companyID)
		UPDATE cmp SET 
			persName=@persName, 
			manager=@managerID, 
			persSurname=@persSurname, 
			persEmail=@persEmail, 
			persPhone=@persPhone,
			persDate=@persDate, 
			persGender=@persGender, 
			persPatronymic=@persPatronymic, 
			compContact=@compContact,
			compContactPost=@compContactPost, 
			compSite=@compSite, 
			compType=@compType, 
			tags=@tags 
		FROM
			uchet.dbo.comparam cmp
		WHERE 
			cmp.upcode=@companyID
	END
	ELSE
	BEGIN
		--���� ������ �� ������, �� ��������� �����
		--����� ������� ����. ����� ������� ����� � �����.
		;with numbers AS (
			select code=10000+ROW_NUMBER() over (ORDER BY n1)
			from 
				(select top 500 n1=number from master.dbo.spt_values) v1 
			full join 
				(select top 300 n2=number from master.dbo.spt_values) v2 on 1=1)
		SELECT TOP 1 @companyID=n.code 
		from numbers n
		LEFT JOIN uchet.dbo.company c (NOLOCK) ON n.code=c.code
		WHERE ISNULL(c.code,0)=0
		ORDER BY n.code	
		
		IF @companyID IS NULL
			RETURN -1
		
		exec uchet.dbo.InitProcess 555,0

		IF @type='���'
		BEGIN
			print 'Not working'
		END	
		IF @type='������'
		BEGIN
			SET IDENTITY_INSERT uchet.dbo.company ON
			
			INSERT INTO uchet.dbo.company (code,upcode,name,company,phone,inn,kpp,bank,kod_mfo,acc1,acc2,email,address,RealAddres,region)
			SELECT 
				code=@companyID,
				upcode=345, 
				name='[������]'+CASE WHEN ISNULL(@name,'')='' THEN 
						CASE WHEN ISNULL(@persSurname+' '+@persName+' '+@persPatronymic,'')='' THEN ISNULL(@persSurname+' '+@persName+' '+@persPatronymic,'') 
						ELSE cast(@amoID AS varchar(10)) END
					ELSE ISNULL(@fullname,'') END,
				company=ISNULL(@fullname,''),
				phone=ISNULL(@phone,''),
				inn=@inn,
				kpp=@kpp,
				bank=@bank,
				kod_mfo=@bik,
				acc1=@acc1,
				acc2=@acc2,
				email=@email,
				address=@address,
				RealAddres=@RealAddres,
				region=@regionID

			SET IDENTITY_INSERT uchet.dbo.company OFF

			--���������� ���. ����������	
			IF NOT EXISTS(SELECT code FROM uchet.dbo.comparam WHERE upcode=@companyID)
				INSERT INTO uchet.dbo.comparam (upcode) VALUES (@companyID)

			UPDATE cmp SET 
				amoID=@amoID,
				persName=@persName, 
				manager=@managerID, 
				persSurname=@persSurname, 
				persEmail=@persEmail, 
				persPhone=@persPhone,
				persDate=@persDate, 
				persGender=@persGender, 
				persPatronymic=@persPatronymic, 
				compContact=@compContact,
				compContactPost=@compContactPost, 
				compSite=@compSite, 
				compType=@compType, 
				tags=@tags 
			FROM
				uchet.dbo.comparam cmp
			WHERE 
				cmp.upcode=@companyID
		END	
		IF @type='�������'
		BEGIN
			print 'Not working'
		END
	END
END

