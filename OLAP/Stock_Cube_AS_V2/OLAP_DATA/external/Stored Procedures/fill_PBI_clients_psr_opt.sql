



--Заполнение таблицы фактов для PowerBI

CREATE PROCEDURE [external].[fill_PBI_clients_psr_opt]

AS
SET DATEFORMAT dmy;
	TRUNCATE TABLE [external].[PBI_clients_psr_opt]
	;WITH 
		client AS (
		SELECT
		code,
		company,
		email,
		nick,
		status=CASE Status WHEN 1 THEN 'ЮЛ' ELSE 'ЧЛ' END
		FROM uchet.dbo.company c (NOLOCK)
		WHERE nick IN ('ПСР','ОПТ')),
		orders AS (SELECT
		c_to, 
		maxdate=MAX(date),
		sumtotal=sum(total), counttotal=COUNT(*),
		sum2019=SUM(CASE WHEN year(date)=2019 THEN total ELSE 0 END),
		count2019=SUM(CASE WHEN year(date)=2019 THEN 1 ELSE 0 END)
		FROM uchet.dbo.doc_ref ord (NOLOCK)
		WHERE type_doc LIKE 'СМо%'
		GROUP BY c_to
		) 
	

INSERT INTO [OLAP_DATA].[external].[PBI_clients_psr_opt]
           ([Тип]
           ,[КодКлиента]
           ,[ФИО]
           ,[email]
           ,[ДатаПоследнегоЗаказа]
           ,[ВсегоСумма]
           ,[ВсегоЗаказов]
           ,[Сумма2019]
           ,[Заказов2019])
	SELECT c.nick, c.code, c.company, c.email, o.maxdate, o.sumtotal,  o.counttotal, o.sum2019, o.count2019
	FROM  client c
	INNER JOIN orders o
	ON c.code=o.c_to
	ORDER BY nick