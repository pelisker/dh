CREATE TABLE [dbo].[OstatqClients_fact] (
    [row_status]         CHAR (1) NULL,
    [date]               INT      NOT NULL,
    [productID]          INT      NOT NULL,
    [clientID]           INT      NOT NULL,
    [reservClient]       MONEY    NOT NULL,
    [reservClientAmount] MONEY    NOT NULL
);

