CREATE TABLE [dbo].[Region_Dim] (
    [id]     INT           NOT NULL,
    [NameL1] VARCHAR (150) NOT NULL,
    [NameL2] VARCHAR (150) NULL,
    [NameL3] VARCHAR (150) NULL,
    CONSTRAINT [PK_Region_Dim] PRIMARY KEY CLUSTERED ([id] ASC)
);

