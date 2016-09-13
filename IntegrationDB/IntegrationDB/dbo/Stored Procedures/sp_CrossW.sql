CREATE PROC [dbo].[sp_CrossW]
 @table       AS sysname,        
 @onrows      AS nvarchar(256),  
 @onrowsalias AS sysname = NULL, 
 @oncols      AS nvarchar(256),  
 @sumcol      AS sysname = NULL ,
 @Condition as nvarchar (256)
AS

DECLARE
 @sql AS nvarchar (max),
 @NEWLINE AS char(1)

SET @NEWLINE = CHAR(10)

SET @sql =
 'SELECT' + @NEWLINE + 
 '  ' + @onrows +
 CASE
   WHEN @onrowsalias IS NOT NULL THEN ' AS ' + @onrowsalias
   ELSE ''
 END

CREATE TABLE #keys(keyvalue nvarchar(100) NOT NULL PRIMARY KEY)

DECLARE @keyssql AS varchar(1000)
SET @keyssql = 
 'INSERT INTO #keys ' +
 'SELECT DISTINCT CAST(' +@oncols + ' AS nvarchar(100)) ' +
 'FROM ' + @table

EXEC (@keyssql)

DECLARE @key AS nvarchar(100)
SELECT @key = MIN(keyvalue) FROM #keys

WHILE @key IS NOT NULL
BEGIN
 SET @sql = @sql + ','                   + @NEWLINE +
   '  MAX(CASE CAST(' + @oncols +
                    ' AS NVARCHAR(100))' + @NEWLINE +
   '        WHEN N''' + @key +
          ''' THEN ' + @sumcol+ @NEWLINE +
   '        ELSE NULL'                      + @NEWLINE +
   '      END) AS [' + @key+']'
 
 SELECT @key = MIN(keyvalue) FROM #keys
 WHERE keyvalue > @key
END

SET @sql = @sql         + @NEWLINE +
 'FROM ' + @table      + @NEWLINE +
 @condition+@NEWLINE+
 'GROUP BY ' + @onrows + @NEWLINE +
 'ORDER BY ' + @onrows

PRINT @sql  + @NEWLINE
EXEC (@sql)
