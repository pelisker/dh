CREATE TABLE [dbo].[Product_Dim] (
    [id]               INT           NOT NULL,
    [Name]             VARCHAR (150) NOT NULL,
    [Brand]            VARCHAR (150) NOT NULL,
    [Model]            VARCHAR (150) NOT NULL,
    [Class1]           VARCHAR (50)  NOT NULL,
    [Class2]           VARCHAR (50)  NOT NULL,
    [Subtype]          VARCHAR (50)  NULL,
    [Interval]         VARCHAR (50)  NULL,
    [Manufacturer]     VARCHAR (50)  NULL,
    [lastCutPriceDate] DATE          NULL,
    CONSTRAINT [PK_Products_Dim] PRIMARY KEY CLUSTERED ([id] ASC)
);

