CREATE TABLE [dbo].[IlliquidGoods_fact] (
    [date]                   INT   NOT NULL,
    [productID]              INT   NOT NULL,
    [illiquidgoods]          MONEY NOT NULL,
    [costAmountCurrent]      MONEY NOT NULL,
    [salesFromLastDate]      MONEY NOT NULL,
    [illiquidgoods3m]        MONEY NOT NULL,
    [illiquidgoods6m]        MONEY NOT NULL,
    [illiquidgoods1y]        MONEY NOT NULL,
    [price3m]                MONEY NOT NULL,
    [price6m]                MONEY NOT NULL,
    [price1y]                MONEY NOT NULL,
    [priceActionCurrent]     MONEY NOT NULL,
    [salesFromLastDateQ]     MONEY NULL,
    [amount3m]               MONEY NULL,
    [amount6m]               MONEY NULL,
    [amount1y]               MONEY NULL,
    [costAmountCurrentTotal] MONEY NULL,
    CONSTRAINT [PK_illiquidGoods_fact] PRIMARY KEY CLUSTERED ([date] ASC, [productID] ASC)
);

