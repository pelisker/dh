-- =============================================
-- Author:		SC
-- Create date: 18.04.16
-- Description:	Загрузка остатков из SV
-- =============================================
CREATE PROCEDURE [dbo].[Upload_intTovar]
AS
BEGIN
	SET NOCOUNT ON;


    MERGE intTovar AS target
    USING (	SELECT [code]
		  ,name=ISNULL(name,'')
		  ,massa=ISNULL(massa,0)
		  ,volume=ISNULL(volume,0)
		  ,[ost]=ISNULL([ost],0)
		  ,[way]=ISNULL([way],0)
		  ,priceRoz=ISNULL(priceRoz,0)
		  ,priceAct=ISNULL(priceAct,0)
	FROM [uchet].[dbo].[vIMOstat]) AS source (code, name, massa, volume, ost, way, priceRoz, priceAct)
    ON (target.code = source.code)
    WHEN MATCHED THEN 
        UPDATE SET name=source.name, massa=source.massa, volume=source.volume, Ost = source.ost
        , Way=source.way, priceRoz=source.priceRoz, priceAct=source.priceAct
	WHEN NOT MATCHED THEN	
	    INSERT (code, name, ost, way, massa, volume, priceRoz, priceAct)
	    VALUES (source.code, source.name, source.massa, source.volume, source.ost, source.way, source.priceRoz, source.priceAct)
	WHEN NOT MATCHED BY SOURCE THEN	
		DELETE;



	--INSERT INTO intOstat (tovar,ostStock,ostWay)
	--SELECT [code]
	--	  ,[ost]
	--	  ,[way]
	--FROM [uchet].[dbo].[vIMOstat]
END

