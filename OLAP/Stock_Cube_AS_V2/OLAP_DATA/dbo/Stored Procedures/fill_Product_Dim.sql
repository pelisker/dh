

--Заполнение измерения - товары

CREATE PROCEDURE [dbo].[fill_Product_Dim]

AS

TRUNCATE TABLE dbo.Product_Dim


;WITH
hist AS (
--Истори цен
select spy.date, nh.code, nh.price05
from uchet.dbo.spy (nolock)
inner join
uchet.dbo.NomHist nh (NOLOCK) ON nh.upcode=spy.id
where spy.alias='nomencl' and spy.fields like '%Цена05%'
)
INSERT INTO dbo.Product_Dim (id,name,Brand, Model, Class1, Class2, subtype, Manufacturer, lastCutPriceDate)
SELECT n.code, n.name, ISNULL(brand.name,''), ISNULL(model.name,''), ISNULL(c1.Name, ''), ISNULL(c2.Name, ''), ISNULL(subtype.Name, '')
	,ISNULL(man.Name, '')
	,lastCutPriceDate=ISNULL((select MAX(date) from hist where price05>n.price05 and code=n.code),'01.01.1900')
FROM uchet.dbo.nomencl n (NOLOCK)
	LEFT JOIN uchet.dbo.nomparam np (NOLOCK)
		ON n.code=np.upcode
	LEFT JOIN uchet.dbo.class c1
		ON n.upcode = c1.code
	LEFT JOIN uchet.dbo.class c2
		ON c1.upcode = c2.code AND c2.upcode=5120
	LEFT JOIN uchet.dbo.complect model (NOLOCK)
		ON np.brand = model.code AND model.code!=0
	LEFT JOIN uchet.dbo.complect brand (NOLOCK)
		ON model.upcode = brand.code
	LEFT JOIN uchet.dbo.complect subtype (NOLOCK)
		ON np.subtype=subtype.code AND ISNULL(subtype.code,0)!=0
	LEFT JOIN uchet.dbo.company man (NOLOCK)
		ON np.manufacturer=man.code AND ISNULL(man.code,0)!=0

UNION
SELECT 0, 'Не найден', '', '', '', '','','','01.01.1900'