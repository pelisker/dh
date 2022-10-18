CREATE TABLE [external].[PBI_sales] (
    [Дата]                   DATE           NOT NULL,
    [Дата резерва]           DATE           NOT NULL,
    [ID заказа]              INT            NOT NULL,
    [ID счета]               INT            NOT NULL,
    [Номер]                  VARCHAR (20)   NOT NULL,
    [Номер счета]            VARCHAR (20)   NOT NULL,
    [Клиент]                 VARCHAR (200)  NOT NULL,
    [Клиенты папка]          VARCHAR (200)  NOT NULL,
    [Источник]               VARCHAR (200)  NOT NULL,
    [Город]                  VARCHAR (200)  NOT NULL,
    [Область]                VARCHAR (200)  NOT NULL,
    [utm]                    VARCHAR (2000) NULL,
    [Сумма заказа]           MONEY          NOT NULL,
    [Доставка]               MONEY          NOT NULL,
    [Доставка факт]          MONEY          NULL,
    [Себестоимость доставки] MONEY          NULL,
    [Возвраты]               MONEY          NOT NULL,
    [Сумма минус возвраты]   MONEY          NULL,
    [Способ доставки]        VARCHAR (100)  NOT NULL,
    [Объем ТК]               MONEY          NULL,
    [Вес ТК]                 MONEY          NULL,
    [Объем]                  MONEY          NULL,
    [Вес]                    MONEY          NULL,
    [Трекинговый номер]      VARCHAR (50)   NULL,
    [Тип клиента]            VARCHAR (50)   NULL,
    [Способ оплаты]          VARCHAR (50)   NULL,
    CONSTRAINT [PK_PBI_sales] PRIMARY KEY CLUSTERED ([Дата] ASC, [ID счета] ASC, [Клиент] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[external].[PBI_sales] TO [ExternalBiUser]
    AS [dbo];

