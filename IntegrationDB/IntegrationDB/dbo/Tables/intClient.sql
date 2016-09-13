CREATE TABLE [dbo].[intClient] (
    [code]         INT             NOT NULL,
    [name]         NVARCHAR (200)  NULL,
    [phone]        NVARCHAR (50)   NULL,
    [city]         NVARCHAR (50)   NULL,
    [email]        NVARCHAR (150)  NULL,
    [c_referrer]   NVARCHAR (50)   NULL,
    [utm_source]   NVARCHAR (50)   NULL,
    [utm_medium]   NVARCHAR (2000) NULL,
    [utm_term]     NVARCHAR (2000) NULL,
    [utm_content]  NVARCHAR (2000) NULL,
    [sv]           BIT             NULL,
    [utm_campaign] NVARCHAR (2000) NULL,
    CONSTRAINT [PK_intClient] PRIMARY KEY CLUSTERED ([code] ASC)
);


GO
GRANT DELETE
    ON OBJECT::[dbo].[intClient] TO [BitrixUser]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[intClient] TO [BitrixUser]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[intClient] TO [BitrixUser]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[intClient] TO [BitrixUser]
    AS [dbo];

