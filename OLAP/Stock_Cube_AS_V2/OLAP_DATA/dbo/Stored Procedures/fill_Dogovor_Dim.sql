



--Заполнение измерения - регионы

CREATE PROCEDURE [dbo].[fill_Dogovor_Dim]
AS

DELETE FROM dbo.Dogovor_Dim 

INSERT INTO dbo.Dogovor_Dim (id,NameL1,NameL2)
SELECT
	id=l2.code,
	nameL1=L1.name, 
	nameL2=L2.name
FROM uchet.dbo.Dogovor L1 (NOLOCK) 
INNER JOIN uchet.dbo.Dogovor L2 (NOLOCK) 
	ON L1.code=L2.upcode
--WHERE l2.IsGroup=0
UNION
SELECT 0, 'Не найден','Не найден'