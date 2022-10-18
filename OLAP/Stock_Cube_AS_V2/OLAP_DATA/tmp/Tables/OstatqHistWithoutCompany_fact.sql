CREATE TABLE [tmp].[OstatqHistWithoutCompany_fact] (
    [date]     DATE        NOT NULL,
    [account]  VARCHAR (4) NOT NULL,
    [tovar]    INT         NOT NULL,
    [lot]      INT         NOT NULL,
    [quantity] MONEY       NULL,
    CONSTRAINT [PK_OstatqHistWithoutCompany_fact] PRIMARY KEY CLUSTERED ([date] ASC, [account] ASC, [tovar] ASC, [lot] ASC)
);

