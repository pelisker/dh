CREATE TABLE [dbo].[Dogovor_Dim] (
    [id]     INT           NOT NULL,
    [NameL1] VARCHAR (150) NOT NULL,
    [NameL2] VARCHAR (150) NULL,
    CONSTRAINT [PK_Dogovor_Dim] PRIMARY KEY CLUSTERED ([id] ASC)
);

