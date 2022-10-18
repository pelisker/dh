

--Заполнение таблицы фактов резервы по клиентам

CREATE PROCEDURE [dbo].[fill_OstatqClients_Fact]

AS
SET DATEFORMAT dmy;

	DELETE FROM [dbo].[OstatqClients_fact] WHERE [date]=datepart(YEAR,GETDATE())*10000 + datepart(M,GETDATE())*100 + datepart(D,GETDATE())

	UPDATE [dbo].[OstatqClients_fact] SET [row_status]='D' WHERE [row_status]='I'

	INSERT INTO [dbo].[OstatqClients_fact]
		(
			[row_status],
			[date],
			[ClientID],
			[productID],
			[reservClient],
			[reservClientAmount]
		)
	SELECT
		[row_status]='I',
		[date]=datepart(YEAR,GETDATE())*10000 + datepart(M,GETDATE())*100 + datepart(D,GETDATE()),
		[ClientID]=dr.c_to,
		[productID]=dc.tovar,
		[reservClient]=SUM(dc.quantity),
		[reservClientAmoiunt]=SUM(dc.amount)
	FROM uchet.dbo.document dc (nolock) 
	INNER JOIN uchet.dbo.doc_ref dr (nolock)
		ON dc.upcode=dr.code
	WHERE dr.owner=23 and dc.oper=47
	GROUP BY 
		dr.c_to, 
		dc.tovar