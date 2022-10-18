

--Заполнение измерения - департаменты

CREATE PROCEDURE [dbo].[fill_Client_Dim]

AS

DELETE FROM dbo.Client_Dim 
INSERT INTO dbo.Client_Dim (id,folder,Name,tip)
SELECT c.code, folder=ISNULL(f.name,'Нет папки'), c.name, 
tip=CASE WHEN c.nick NOT IN ('РОЗ','ПСР','ОПТ','ДИЛЕР' ) THEN 'РОЗ' ELSE c.nick END
FROM uchet.dbo.company c (NOLOCK)
LEFT JOIN 
uchet.dbo.company f (NOLOCK) ON c.upcode=f.code
UNION
SELECT 0, 'Не найден','Не найден','Не найден'


--SELECT code, name
--FROM uchet.dbo.dogovor
--WHERE code IN (146) OR (upcode=1 AND isgroup=2)
--UNION
--SELECT code, name
--FROM uchet.dbo.company
--WHERE (upcode IN (276) AND isgroup=2) or code IN (334,301,331,367,332,390,193,1,3,22,276,500)
--UNION
--SELECT 0, 'Не найден'