﻿CREATE TABLE [dbo].[Ostatq_fact] (
    [date]                 INT   NOT NULL,
    [productID]            INT   NOT NULL,
    [parcelID]             INT   NOT NULL,
    [stock]                MONEY NOT NULL,
    [freeStock]            MONEY NOT NULL,
    [reserv]               MONEY NOT NULL,
    [way]                  MONEY NOT NULL,
    [way_reserv]           MONEY NOT NULL,
    [stock_without_parcel] INT   NOT NULL,
    [reservWithPay]        MONEY NOT NULL,
    [reservWithoutPay]     MONEY NOT NULL,
    [reservWayPay]         MONEY NOT NULL,
    [reservStockPay]       MONEY NOT NULL,
    [costAmountCurrent]    MONEY NULL,
    [illiquidgoods3m]      MONEY NULL,
    [illiquidgoods6m]      MONEY NULL,
    [illiquidgoods1y]      MONEY NULL,
    [price3m]              MONEY NULL,
    [price6m]              MONEY NULL,
    [price1y]              MONEY NULL,
    [priceActionCurrent]   MONEY NULL,
    CONSTRAINT [PK_Ostatq_fact] PRIMARY KEY CLUSTERED ([date] ASC, [productID] ASC, [parcelID] ASC)
);

