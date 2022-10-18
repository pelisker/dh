
CREATE view [bi].[Supply_fact] as 
SELECT [date]
      ,[id]
      ,[nn]
      ,[parcelID]
      ,[productID]
      ,[quantity]
      ,[amount]
      ,[costamount]
      ,[currency]
  FROM [OLAP_DATA].[dbo].[Supply_fact]