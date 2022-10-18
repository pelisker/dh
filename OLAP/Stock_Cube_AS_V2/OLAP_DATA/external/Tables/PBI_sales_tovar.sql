CREATE TABLE [external].[PBI_sales_tovar] (
    [id]                 INT           NOT NULL,
    [ID РН]              INT           NOT NULL,
    [Код товара]         INT           NOT NULL,
    [Товар]              VARCHAR (200) NOT NULL,
    [Бренд]              VARCHAR (200) NOT NULL,
    [Модель]             VARCHAR (200) NOT NULL,
    [Количество продажи] MONEY         NOT NULL,
    [Сумма продажи]      MONEY         NOT NULL,
    CONSTRAINT [PK_PBI_sales_tovar] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[external].[PBI_sales_tovar] TO [ExternalBiUser]
    AS [dbo];

