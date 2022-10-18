


--Заполнение таблицы фактов
CREATE PROCEDURE [external].[fill_PBI_sales_tovar]

AS
SET DATEFORMAT dmy;
	TRUNCATE TABLE [external].[PBI_sales_tovar]
	;WITH
	opers AS (
		SELECT oper=upcode, account=acck FROM uchet.dbo.oper (NOLOCK) GROUP BY upcode, acck HAVING SUM(CASE WHEN oper.acck IN ('021'/*,'03'*/) THEN 1 ELSE 0 END)>0
		),
	parcels AS (
		SELECT
			DISTINCT
			id=ISNULL(dr.code,-1),
			parcel=p.code,
			cost=ISNULL(dc.price,0)
		FROM uchet.dbo.Parcel p (NOLOCK) 
		LEFT JOIN uchet.dbo.document dc (NOLOCK) 
			ON dc.code=p.upcode
		LEFT JOIN uchet.dbo.doc_ref dr (NOLOCK) 
			ON dc.upcode=dr.code
	),

	trans AS (
		--Продажи
		SELECT
           [id]=dc.code
           ,[ID РН]=rn.code
           ,[Код товара]=dc.tovar
           ,[Товар]=n.name
           ,[Бренд]=ISNULL(brand.name,'')
           ,[Модель]=ISNULL(model.name,'')
           ,[Количество продажи]=CASE WHEN rn.type_doc='ПСР' THEN 0 ELSE dc.quantity END --Убраны количества из ПСР
           ,[Сумма продажи]=dc.amount
--SELECT n.code,  ISNULL(c1.Name, ''), ISNULL(c2.Name, ''), ISNULL(subtype.Name, '')
		
		FROM uchet.dbo.doc_ref rn
		INNER JOIN uchet.dbo.document dc (NOLOCK) 
			ON rn.code=dc.upcode
		INNER JOIN opers 
			ON opers.oper=dc.oper
		INNER JOIN uchet.dbo.nomencl n (NOLOCK)
			ON n.code=dc.tovar
		LEFT JOIN uchet.dbo.nomparam np (NOLOCK)
			ON n.code=np.upcode
		--LEFT JOIN uchet.dbo.class c1
		--	ON n.upcode = c1.code
		--LEFT JOIN uchet.dbo.class c2
		--	ON c1.upcode = c2.code AND c2.upcode=5120
		LEFT JOIN uchet.dbo.complect model (NOLOCK)
			ON np.brand = model.code AND model.code!=0
		LEFT JOIN uchet.dbo.complect brand (NOLOCK)
			ON model.upcode = brand.code
		--LEFT JOIN uchet.dbo.complect subtype (NOLOCK)
		--	ON np.subtype=subtype.code AND ISNULL(subtype.code,0)!=0

		WHERE
		rn.type_doc!='П/Н+'
		and rn.owner=23
		and rn.date > '31.12.2014'
		and dc.quantity>0
		)

INSERT INTO [OLAP_DATA].[external].[PBI_sales_tovar]
           ([id]
           ,[ID РН]
           ,[Код товара]
           ,[Товар]
           ,[Бренд]
           ,[Модель]
           ,[Количество продажи]
           ,[Сумма продажи])

	SELECT
			[id]
           ,[ID РН]
           ,[Код товара]
           ,[Товар]
           ,[Бренд]
           ,[Модель]
           ,[Количество продажи]
           ,[Сумма продажи]
	FROM trans