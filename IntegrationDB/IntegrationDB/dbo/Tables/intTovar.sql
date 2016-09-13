CREATE TABLE [dbo].[intTovar] (
    [code]     INT           NOT NULL,
    [name]     VARCHAR (150) NOT NULL,
    [massa]    MONEY         NULL,
    [volume]   MONEY         NULL,
    [Ost]      INT           NULL,
    [Way]      INT           NULL,
    [priceRoz] MONEY         NULL,
    [priceAct] MONEY         NULL,
    CONSTRAINT [PK_intTovar] PRIMARY KEY CLUSTERED ([code] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[intTovar] TO [BitrixUser]
    AS [dbo];

