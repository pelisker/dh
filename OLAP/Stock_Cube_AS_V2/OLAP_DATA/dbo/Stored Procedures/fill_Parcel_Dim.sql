



--Заполнение измерения - регионы

CREATE PROCEDURE [dbo].[fill_Parcel_Dim]
AS

DELETE FROM dbo.Parcel_Dim 

INSERT INTO dbo.Parcel_Dim (id,Nn,Date,Supplier)
SELECT
	DISTINCT
	id=ISNULL(dr.code,-1),
	nn=ISNULL(dr.nn,'Партия не найдена'), 
	date=ISNULL(dr.date,'01.01.01'),
	Supplier=ISNULL(c.name,'Нет')
FROM uchet.dbo.Parcel p (NOLOCK) 
LEFT JOIN uchet.dbo.document dc (NOLOCK) 
	ON dc.code=p.upcode
LEFT JOIN uchet.dbo.doc_ref dr (NOLOCK) 
	ON dc.upcode=dr.code
LEFT JOIN uchet.dbo.company c (NOLOCK) 
	ON dr.c_from=c.code

--WHERE l2.IsGroup=0
UNION
SELECT 0, 'Без партии','01.01.01',''