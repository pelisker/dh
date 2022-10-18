


--Заполнение таблицы фактов для PowerBI

CREATE PROCEDURE [external].[fill_PBI_psr]

AS
SET DATEFORMAT dmy;
	TRUNCATE TABLE [external].PBI_psr
	;WITH
	psr AS (SELECT psr.date, amount=SUM(dc.amount) 
		FROM uchet.dbo.doc_ref psr (NOLOCK)
		LEFT JOIN uchet.dbo.document dc (NOLOCK) ON psr.code=dc.upcode 
		WHERE dc.oper=549 GROUP BY psr.date
	)
	
	

INSERT INTO [OLAP_DATA].[external].[PBI_psr]
           ([Дата ПСР]
           ,[Сумма ПСР])
	SELECT
		date
		,amount
	FROM psr