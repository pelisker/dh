CREATE TABLE [tmp].[Ostatq_hist_fact] (
    [date]     DATE        NOT NULL,
    [dt]       DATE        NOT NULL,
    [time]     INT         NOT NULL,
    [account]  VARCHAR (4) NOT NULL,
    [tovar]    INT         NOT NULL,
    [company]  INT         NOT NULL,
    [parcel]   INT         NOT NULL,
    [lot]      INT         NOT NULL,
    [cost]     MONEY       NOT NULL,
    [quantity] MONEY       NULL,
    CONSTRAINT [PK_ostatq_hist] PRIMARY KEY CLUSTERED ([date] ASC, [dt] ASC, [time] ASC, [account] ASC, [tovar] ASC, [company] ASC, [parcel] ASC, [lot] ASC, [cost] ASC)
);

