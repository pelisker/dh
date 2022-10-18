CREATE TABLE [dbo].[Parcel_Dim] (
    [ID]       INT          NOT NULL,
    [Nn]       VARCHAR (50) NOT NULL,
    [Date]     DATE         NOT NULL,
    [Supplier] VARCHAR (50) NULL,
    CONSTRAINT [PK_Parcel_Dim] PRIMARY KEY CLUSTERED ([ID] ASC)
);

