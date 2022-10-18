CREATE TABLE [dbo].[Turnover_fact] (
    [date]       INT   NOT NULL,
    [tovar]      INT   NOT NULL,
    [lot]        INT   NOT NULL,
    [type]       INT   NOT NULL,
    [cost]       MONEY NOT NULL,
    [quantity]   MONEY NULL,
    [ost1year]   MONEY NULL,
    [ost6month]  MONEY NULL,
    [ost3month]  MONEY NULL,
    [ost1month]  MONEY NULL,
    [sale1year]  MONEY NULL,
    [sale6month] MONEY NULL,
    [sale3month] MONEY NULL,
    [sale1month] MONEY NULL,
    CONSTRAINT [PK_Ostatq_hist_fact] PRIMARY KEY CLUSTERED ([date] ASC, [tovar] ASC, [lot] ASC, [type] ASC, [cost] ASC)
);

