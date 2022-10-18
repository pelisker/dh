CREATE TABLE [dbo].[Orders_fact] (
    [date]      DATE         NOT NULL,
    [date_rez]  DATE         NOT NULL,
    [id]        INT          NOT NULL,
    [nn]        VARCHAR (20) NOT NULL,
    [type_doc]  CHAR (10)    NOT NULL,
    [managerID] INT          NOT NULL,
    [clientID]  INT          NOT NULL,
    [regionID]  INT          NOT NULL,
    [amount]    MONEY        NOT NULL,
    [delivery]  MONEY        NOT NULL,
    CONSTRAINT [PK_Orders_fact] PRIMARY KEY CLUSTERED ([date] ASC, [id] ASC)
);

