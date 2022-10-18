CREATE TABLE [dbo].[Supply_fact] (
    [date]       INT          NOT NULL,
    [id]         INT          NOT NULL,
    [nn]         VARCHAR (20) NOT NULL,
    [parcelID]   INT          NOT NULL,
    [productID]  INT          NOT NULL,
    [quantity]   MONEY        NOT NULL,
    [amount]     MONEY        NOT NULL,
    [costamount] MONEY        NOT NULL,
    [currency]   VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_Supply_fact] PRIMARY KEY CLUSTERED ([date] ASC, [id] ASC)
);

