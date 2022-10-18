CREATE TABLE [dbo].[Sales_fact] (
    [date]           INT          NOT NULL,
    [dateOfPay]      INT          NOT NULL,
    [id]             INT          NOT NULL,
    [nn]             VARCHAR (20) NOT NULL,
    [manager]        VARCHAR (50) NOT NULL,
    [salesTerm]      VARCHAR (10) NOT NULL,
    [managerID]      INT          NOT NULL,
    [clientID]       INT          NOT NULL,
    [productID]      INT          NOT NULL,
    [regionID]       INT          NOT NULL,
    [orderID]        INT          NOT NULL,
    [parcelID]       INT          NOT NULL,
    [quantity]       MONEY        NOT NULL,
    [quantityNoLegs] MONEY        NOT NULL,
    [amount]         MONEY        NOT NULL,
    [costamount]     MONEY        NOT NULL,
    [profit]         MONEY        NOT NULL,
    CONSTRAINT [PK_Sales_fact] PRIMARY KEY CLUSTERED ([date] ASC, [dateOfPay] ASC, [id] ASC)
);

