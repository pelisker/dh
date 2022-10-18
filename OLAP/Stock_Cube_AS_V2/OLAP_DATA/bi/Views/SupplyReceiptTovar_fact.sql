

CREATE view [bi].[SupplyReceiptTovar_fact]
AS
SELECT [dateOfReceipt]
      ,[id]
      ,[nn]
      ,[productID]
      ,[quantity]
      ,[costamount]
      ,[currency]
  FROM [OLAP_DATA].[dbo].[SupplyWay_fact]