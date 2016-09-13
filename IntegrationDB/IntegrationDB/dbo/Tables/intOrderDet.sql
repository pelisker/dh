CREATE TABLE [dbo].[intOrderDet] (
    [upcode]   INT            NULL,
    [code]     INT            IDENTITY (1, 1) NOT NULL,
    [tovar]    INT            NULL,
    [quantity] MONEY          NULL,
    [price]    MONEY          NULL,
    [comment]  NVARCHAR (200) NULL,
    [sv]       BIT            NULL,
    CONSTRAINT [PK_intOrderDet] PRIMARY KEY CLUSTERED ([code] ASC)
);


GO
GRANT DELETE
    ON OBJECT::[dbo].[intOrderDet] TO [BitrixUser]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[intOrderDet] TO [BitrixUser]
    AS [dbo];


GO
GRANT REFERENCES
    ON OBJECT::[dbo].[intOrderDet] TO [BitrixUser]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[intOrderDet] TO [BitrixUser]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[intOrderDet] TO [BitrixUser]
    AS [dbo];

