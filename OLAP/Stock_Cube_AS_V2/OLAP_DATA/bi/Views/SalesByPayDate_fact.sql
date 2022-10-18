create view bi.SalesByPayDate_fact
AS
SELECT     dateOfPay, id, nn, manager, salesTerm, managerID, clientID, productID, regionID, orderID, parcelID, quantity, quantityNoLegs, amount, costamount, profit
FROM         dbo.Sales_fact