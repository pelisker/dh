CREATE TABLE [dbo].[time_dim] (
    [date]         DATE         NOT NULL,
    [day]          INT          NULL,
    [month]        VARCHAR (50) NULL,
    [monthNum]     INT          NULL,
    [DayOfWeek]    VARCHAR (50) NULL,
    [DayOfWeekNum] INT          NULL,
    [year]         INT          NULL,
    CONSTRAINT [PK_time_dim] PRIMARY KEY CLUSTERED ([date] ASC)
);

