


--Заполнение измерения - регионы

CREATE PROCEDURE [dbo].[fill_Region_Dim]
AS

DELETE FROM dbo.Region_Dim 

--;WITH 
----dro AS (SELECT distinct name=ltrim(rtrim(dro.City)) FROM uchet.dbo.DrfOrder dro WHERE ISNULL(City,'')!=''),
--drd AS (SELECT distinct name=ltrim(rtrim(replace(replace(drd.ai_city,'г.',''),'г ',''))) FROM uchet.dbo.DrfDelivery drd WHERE ISNULL(drd.ai_city,'')!=''),
--reg AS (/*SELECT name FROM dro UNION*/ SELECT name FROM drd)

INSERT INTO dbo.Region_Dim (id,NameL1,NameL2,NameL3)
SELECT
	id=l3.code,
	nameL1=L1.name, 
	nameL2=L2.name, 
	nameL3=L3.name
FROM uchet.dbo.region L1 (NOLOCK) 
INNER JOIN uchet.dbo.region L2 (NOLOCK) 
	ON L1.code=L2.upcode
INNER JOIN uchet.dbo.region L3 (NOLOCK) 
	ON L2.code=L3.upcode
WHERE l1.upcode=500
UNION
SELECT 0, 'Не найден','Не найден','Не найден'