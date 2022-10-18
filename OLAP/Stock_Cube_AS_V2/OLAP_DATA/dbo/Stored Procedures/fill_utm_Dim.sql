

--Заполнение измерения - utm меток

CREATE PROCEDURE [dbo].[fill_utm_Dim]

AS

TRUNCATE TABLE dbo.utm_Dim
;WITH orders_utm AS 
(SELECT  distinct
      referrer=replace(CASE WHEN ISNULL(Referrer,'')='' THEN '' ELSE LEFT(referrer,CASE CHARINDEX('/',referrer,CHARINDEX('//',referrer)+2) WHEN 0 THEN LEN(referrer)+1 ELSE CHARINDEX('/',referrer,CHARINDEX('//',referrer)+2) END-1) END,' ','')
      --ISNULL(referrer,'')
      ,utm_source=replace(ISNULL(utmsource,''),' ','')
      ,utm_medium=replace(ISNULL(utmmedium,''),' ','')
      ,utm_term=ISNULL(utmterm,'')
      ,utm_content=ISNULL(utmcontent,'')
      ,utm_campaign=ISNULL(utm_campaign,'')
  FROM uchet.dbo.DrfOrder),
clients_utm AS 
(SELECT  distinct
      referrer=replace(CASE WHEN ISNULL(Referrer,'')='' THEN '' ELSE LEFT(referrer,CASE CHARINDEX('/',referrer,CHARINDEX('//',referrer)+2) WHEN 0 THEN LEN(referrer)+1 ELSE CHARINDEX('/',referrer,CHARINDEX('//',referrer)+2) END-1) END,' ','')
      ,utm_source=replace(ISNULL(utm_source,''),' ','')
      ,utm_medium=replace(ISNULL(utm_medium,''),' ','')
      ,utm_term=ISNULL(utm_term,'')
      ,utm_content=ISNULL(utm_content,'')
      ,utm_campaign=ISNULL(utm_campaign,'')
  FROM uchet.dbo.comparam)
insert into utm_Dim (id,referrer, utm_campaign, utm_content, utm_medium, utm_source, utm_term)
SELECT ROW_NUMBER() OVER (ORDER BY referrer), referrer, utm_campaign, utm_content, utm_medium, utm_source, utm_term 
FROM
(SELECT *
FROM  orders_utm
UNION 
SELECT *
FROM  clients_utm
) AS utm

insert into utm_Dim (id,referrer, utm_campaign, utm_content, utm_medium, utm_source, utm_term)
SELECT 0, referrer='Не найдено', utm_campaign='Не найдено', utm_content='Не найдено', utm_medium='Не найдено', utm_source='Не найдено', utm_term='Не найдено'