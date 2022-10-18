CREATE TABLE [dbo].[utm_Dim] (
    [ID]           INT             NOT NULL,
    [referrer]     NVARCHAR (2000) NULL,
    [utm_source]   NVARCHAR (500)  NULL,
    [utm_medium]   NVARCHAR (2000) NULL,
    [utm_term]     NVARCHAR (2000) NULL,
    [utm_content]  NVARCHAR (500)  NULL,
    [utm_campaign] NVARCHAR (2000) NULL,
    CONSTRAINT [PK_utm_Dim] PRIMARY KEY CLUSTERED ([ID] ASC)
);

