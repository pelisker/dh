

create view [bi].[SupplyPaidTovar_fact]
AS
SELECT [dateOfPay]
      ,[id]
      ,[nn]
      ,[productID]
      ,[quantity]
      ,[costamount]
      ,[currency]
  FROM [OLAP_DATA].[dbo].[SupplyWay_fact]