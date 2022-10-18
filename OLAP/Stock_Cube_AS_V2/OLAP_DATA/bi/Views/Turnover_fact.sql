



CREATE view [bi].[Turnover_fact]

AS

SELECT [date]
      ,[tovar]
      ,[lot]
      ,[type]
      ,[cost]
      ,[quantity]
      ,[ost1year]
      ,[ost6month]
      ,[ost3month]
      ,[ost1month]
      ,[sale1year]
      ,[sale6month]
      ,[sale3month]
      ,[sale1month]
  FROM [OLAP_DATA].[dbo].[Turnover_fact]