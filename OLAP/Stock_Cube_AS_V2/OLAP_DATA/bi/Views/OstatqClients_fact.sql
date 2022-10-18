


CREATE VIEW [bi].[OstatqClients_fact]
AS
SELECT     
	date, 
	productID, 
	clientID, 
	reservClient, 
	reservClientAmount
FROM         dbo.OstatqClients_fact
WHERE     (row_status = 'I')