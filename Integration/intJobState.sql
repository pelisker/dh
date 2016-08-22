USE [Integration]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[intJobState]') AND type in (N'U'))
DROP TABLE [dbo].[intJobState]
GO


CREATE TABLE [dbo].[intJobState](
	[code] [int] NOT NULL,
	[Name] [nvarchar](2000) NULL,
	[lastRun] datetime NULL,
	[lastDate] datetime NULL,
	[Result] [nvarchar](2000) NULL,
	[Error] [nvarchar](2000) NULL,
	[success] bit,
 CONSTRAINT [PK_intJobState] PRIMARY KEY CLUSTERED 
(
	[code] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

