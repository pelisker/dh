CREATE TABLE [dbo].[intCompany] (
    [code]            INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [persSurname]     VARCHAR (50)    NULL,
    [persName]        VARCHAR (50)    NULL,
    [persPatronymic]  VARCHAR (50)    NULL,
    [persDate]        VARCHAR (50)    NULL,
    [persGender]      TINYINT         NULL,
    [persPhone]       VARCHAR (50)    NULL,
    [persEmail]       VARCHAR (100)   NULL,
    [compSite]        VARCHAR (100)   NULL,
    [compContact]     VARCHAR (150)   NULL,
    [compContactPost] VARCHAR (50)    NULL,
    [tags]            VARCHAR (2000)  NULL,
    [compType]        TINYINT         NULL,
    [compName]        VARCHAR (500)   NULL,
    [compPhone]       VARCHAR (50)    NULL,
    [compEmail]       VARCHAR (100)   NULL,
    [persCity]        VARCHAR (100)   NULL,
    [Date]            DATE            NULL,
    [utm_source]      NVARCHAR (50)   NULL,
    [utm_medium]      NVARCHAR (2000) NULL,
    [utm_term]        NVARCHAR (2000) NULL,
    [manager]         INT             NULL,
    [tell_activity]   VARCHAR (2000)  NULL,
    [sv]              BIT             CONSTRAINT [DF_intCompany_sv] DEFAULT ((0)) NULL,
    [utm_content]     NVARCHAR (2000) NULL,
    [utm_campaign]    NVARCHAR (2000) NULL,
    [referrer]        NVARCHAR (2000) NULL,
    CONSTRAINT [PK_intCcompany] PRIMARY KEY CLUSTERED ([code] ASC) WITH (FILLFACTOR = 97, PAD_INDEX = ON)
);


GO
GRANT DELETE
    ON OBJECT::[dbo].[intCompany] TO [BitrixUser]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[intCompany] TO [BitrixUser]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[intCompany] TO [BitrixUser]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[intCompany] TO [BitrixUser]
    AS [dbo];

