


--Заполнение периода висяка у товара

CREATE PROCEDURE [dbo].[fill_ProductInterval_Dim]
AS

WITH intervals AS (
select o.productID , interval=max(CASE WHEN DATEPART(year,getdate()-ISNULL(p.date,'01.01.01'))-1900>0 THEN 13 ELSE DATEPART(month,getdate()-ISNULL(p.date,'01.01.01'))-1 END)
from 
	Parcel_Dim p
	INNER JOIN 
Ostatq_fact o ON p.ID=o.parcelID AND o.stock>0
GROUP BY o.productID)
UPDATE p SET Interval=CASE WHEN ISNULL(i.interval,-1)=-1 THEN '' WHEN ISNULL(i.interval,-1)=0 THEN '< мес.'  WHEN ISNULL(i.interval,0)<13 THEN CAST(i.interval AS varchar(2))+' мес.' ELSE '> 12 мес.' END
FROM Product_Dim p  
LEFT JOIN intervals i ON p.id=i.productID