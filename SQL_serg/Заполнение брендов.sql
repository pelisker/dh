
;WITH tmp AS
(SELECT distinct
      brand=rtrim(LTRIM([brand]))
  FROM [Integration].[dbo].[tmp]
  WHERE ISNULL(brand,'')!='')
  INSERT INTO complect (upcode, name, isgroup)
  SELECT 667, brand,2
	FROM tmp
		LEFT JOIN complect c 
			ON c.upcode=667 AND c.name=tmp.brand COLLATE SQL_Latin1_General_CP1251_CI_AS
  WHERE c.code IS NULL


;WITH tmp AS
(SELECT distinct
      brand=rtrim(LTRIM([brand])),
      model=rtrim(LTRIM(model))
  FROM [Integration].[dbo].[tmp]
  WHERE ISNULL(brand,'')!='')
  INSERT INTO complect (upcode, name, isgroup)
  SELECT c.code, brand, 1
	FROM tmp
		INNER JOIN complect c 
			ON c.upcode=667 AND c.name=tmp.brand COLLATE SQL_Latin1_General_CP1251_CI_AS
		LEFT JOIN complect m 
			ON m.upcode=c.code AND m.name=tmp.model COLLATE SQL_Latin1_General_CP1251_CI_AS
  WHERE m.code IS NULL


;WITH tmp AS
(SELECT
      brand=rtrim(LTRIM([brand])),
      model=rtrim(LTRIM(model)),
      code
  FROM [Integration].[dbo].[tmp]
  WHERE ISNULL(brand,'')!='')
--  INSERT INTO complect (upcode, name, isgroup)
--  SELECT m.code, np.brand,1
update np set brand=m.code
	FROM tmp
		INNER JOIN complect c 
			ON c.upcode=667 AND c.name=tmp.brand COLLATE SQL_Latin1_General_CP1251_CI_AS
		INNER JOIN complect m 
			ON m.upcode=c.code AND m.name=tmp.model COLLATE SQL_Latin1_General_CP1251_CI_AS
		INNER JOIN nomparam np
			ON np.upcode=tmp.code
			
  
  
