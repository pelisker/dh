CREATE TABLE [dbo].[PBI_sales_rn_psr_vzv] (
    [Дата РН]                   DATE          NOT NULL,
    [ID счета]                  INT           NOT NULL,
    [ID РН]                     INT           NOT NULL,
    [Номер РН]                  VARCHAR (20)  NOT NULL,
    [Клиент РН]                 VARCHAR (200) NOT NULL,
    [Клиенты папка РН]          VARCHAR (200) NOT NULL,
    [Сумма РН]                  MONEY         NOT NULL,
    [Доставка РН]               MONEY         NOT NULL,
    [Доставка факт РН]          MONEY         NULL,
    [Себестоимость доставки РН] MONEY         NULL,
    [Способ доставки РН]        VARCHAR (100) NOT NULL,
    [Трекинговый номер РН]      VARCHAR (50)  NULL,
    [Тип продажи]               VARCHAR (20)  NULL,
    CONSTRAINT [PK_PBI_sales_rn_psr_vzv] PRIMARY KEY CLUSTERED ([ID РН] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[PBI_sales_rn_psr_vzv] TO [ExternalBiUser]
    AS [dbo];

