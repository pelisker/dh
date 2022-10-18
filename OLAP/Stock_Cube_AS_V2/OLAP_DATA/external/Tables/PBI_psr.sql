CREATE TABLE [external].[PBI_psr] (
    [Дата ПСР]  DATE  NOT NULL,
    [Сумма ПСР] MONEY NOT NULL,
    CONSTRAINT [PK_PBI_psr] PRIMARY KEY CLUSTERED ([Дата ПСР] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[external].[PBI_psr] TO [ExternalBiUser]
    AS [dbo];

