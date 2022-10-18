CREATE TABLE [dbo].[SupplyWay_fact] (
    [dateOfPay]     INT          NOT NULL,
    [dateOfReceipt] INT          NOT NULL,
    [id]            INT          NOT NULL,
    [nn]            VARCHAR (20) NOT NULL,
    [productID]     INT          NOT NULL,
    [quantity]      MONEY        NOT NULL,
    [costamount]    MONEY        NOT NULL,
    [currency]      VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_SupplyWay_fact] PRIMARY KEY CLUSTERED ([dateOfPay] ASC, [dateOfReceipt] ASC, [id] ASC)
);

