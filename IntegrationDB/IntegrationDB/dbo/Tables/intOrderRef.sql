CREATE TABLE [dbo].[intOrderRef] (
    [code]         INT             NOT NULL,
    [date]         DATETIME        NULL,
    [address]      NVARCHAR (MAX)  NULL,
    [city]         NVARCHAR (50)   NULL,
    [phonenumber]  NVARCHAR (50)   NULL,
    [email]        NVARCHAR (100)  NULL,
    [delivery]     NVARCHAR (50)   NULL,
    [payment]      NVARCHAR (50)   NULL,
    [referrer]     NVARCHAR (50)   NULL,
    [utm_source]   NVARCHAR (50)   NULL,
    [utm_medium]   NVARCHAR (2000) NULL,
    [utm_term]     NVARCHAR (2000) NULL,
    [utm_content]  NVARCHAR (2000) NULL,
    [client]       INT             NULL,
    [sv]           BIT             NULL,
    [deliverycost] MONEY           NULL,
    [utm_campaign] NVARCHAR (2000) NULL,
    CONSTRAINT [PK_Table_1] PRIMARY KEY CLUSTERED ([code] ASC)
);


GO
GRANT DELETE
    ON OBJECT::[dbo].[intOrderRef] TO [BitrixUser]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[intOrderRef] TO [BitrixUser]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[intOrderRef] TO [BitrixUser]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[intOrderRef] TO [BitrixUser]
    AS [dbo];

