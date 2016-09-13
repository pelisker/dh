CREATE TABLE [dbo].[intJobState] (
    [code]     INT             NOT NULL,
    [Name]     NVARCHAR (2000) NULL,
    [lastRun]  DATETIME        NULL,
    [lastDate] DATETIME        NULL,
    [Result]   NVARCHAR (2000) NULL,
    [Error]    NVARCHAR (2000) NULL,
    [success]  BIT             NULL,
    CONSTRAINT [PK_intJobState] PRIMARY KEY CLUSTERED ([code] ASC)
);

