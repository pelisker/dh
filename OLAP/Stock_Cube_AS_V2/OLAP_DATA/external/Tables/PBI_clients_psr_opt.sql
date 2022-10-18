CREATE TABLE [external].[PBI_clients_psr_opt] (
    [Тип]                  NCHAR (10)  NULL,
    [ФИО]                  NCHAR (200) NULL,
    [email]                NCHAR (200) NULL,
    [ДатаПоследнегоЗаказа] DATE        NULL,
    [ВсегоСумма]           MONEY       NULL,
    [ВсегоЗаказов]         INT         NULL,
    [Сумма2019]            MONEY       NULL,
    [Заказов2019]          INT         NULL,
    [КодКлиента]           INT         NULL
);


GO
GRANT SELECT
    ON OBJECT::[external].[PBI_clients_psr_opt] TO [ExternalBiUser]
    AS [dbo];

