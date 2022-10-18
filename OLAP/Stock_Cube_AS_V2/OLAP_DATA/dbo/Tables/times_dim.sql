CREATE TABLE [dbo].[times_dim] (
    [id]           INT          NOT NULL,
    [date]         DATE         NOT NULL,
    [day]          INT          NULL,
    [week]         INT          NULL,
    [month]        VARCHAR (50) NULL,
    [monthNum]     INT          NULL,
    [DayOfWeek]    VARCHAR (50) NULL,
    [DayOfWeekNum] INT          NULL,
    [year]         INT          NULL,
    [dateName]     VARCHAR (10) NULL,
    [diffDay]      INT          NULL,
    CONSTRAINT [PK_times_dim] PRIMARY KEY CLUSTERED ([id] ASC)
);

