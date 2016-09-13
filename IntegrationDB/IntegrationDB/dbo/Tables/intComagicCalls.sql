CREATE TABLE [dbo].[intComagicCalls] (
    [id]          INT            NOT NULL,
    [call_date]   DATETIME       NULL,
    [numa]        VARCHAR (20)   NULL,
    [visitor_id]  INT            NULL,
    [duration]    INT            NULL,
    [ac_id]       INT            NULL,
    [utm_source]  VARCHAR (50)   NULL,
    [utm_medium]  VARCHAR (2000) NULL,
    [utm_term]    VARCHAR (2000) NULL,
    [utm_content] VARCHAR (2000) NULL,
    [referrer]    VARCHAR (50)   NULL,
    [city]        VARCHAR (50)   NULL,
    [sv]          BIT            CONSTRAINT [DF_intComagicCalls_sv] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_int_comagic_calls] PRIMARY KEY CLUSTERED ([id] ASC)
);

