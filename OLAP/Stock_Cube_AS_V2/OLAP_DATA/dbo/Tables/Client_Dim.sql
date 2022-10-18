CREATE TABLE [dbo].[Client_Dim] (
    [id]     INT           NOT NULL,
    [Name]   VARCHAR (150) NOT NULL,
    [Folder] VARCHAR (150) NOT NULL,
    [tip]    VARCHAR (10)  NOT NULL,
    CONSTRAINT [PK_Clients_Dim] PRIMARY KEY CLUSTERED ([id] ASC)
);

