-- =============================================
-- Author:		SC
-- Create date: 30.05.16
-- Description:	Загрузка менеджеров из SV
-- =============================================
CREATE PROCEDURE [dbo].[Fill_intManager]
AS
BEGIN
	SET NOCOUNT ON;

    MERGE intManager AS target
    USING (SELECT dog.[code]
		  ,name=ISNULL(dog.name,'')
		  ,email=pp.email
	FROM [uchet].[dbo].dogovor dog
	INNER JOIN [uchet].[dbo].dogovor folder
		ON dog.upcode=folder.code
	INNER JOIN [uchet].[dbo].[passwordparam] pp
		ON dog.code=CAST(CASE CHARINDEX(',',pp.dogovor) WHEN 0 THEN pp.dogovor ELSE SUBSTRING(pp.dogovor,0,CHARINDEX(',',pp.dogovor)) END AS int)
	INNER JOIN [uchet].[dbo].[password] p
		ON pp.upcode=p.code
	WHERE 
		folder.upcode=1 AND
		p.arm!=5
	) AS source (code, name, email)
    ON (target.code = source.code)
    WHEN MATCHED THEN 
        UPDATE SET name=source.name, email=source.email
	WHEN NOT MATCHED THEN	
	    INSERT (code, name, email)
	    VALUES (source.code, source.name, source.email)
	WHEN NOT MATCHED BY SOURCE THEN	
		DELETE;


END

