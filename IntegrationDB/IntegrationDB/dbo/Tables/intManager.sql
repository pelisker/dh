CREATE TABLE [dbo].[intManager] (
    [code]  INT           NOT NULL,
    [name]  VARCHAR (50)  NOT NULL,
    [eMail] VARCHAR (100) NULL,
    CONSTRAINT [PK_intManager] PRIMARY KEY CLUSTERED ([code] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[intManager] TO [BitrixUser]
    AS [dbo];

