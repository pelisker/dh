sp_configure 'show advanced', 1; 
GO
RECONFIGURE;
GO
sp_configure;
GO


EXEC msdb.sys.sp_helprolemember 'DatabaseMailUserRole';
EXEC msdb.dbo.sysmail_help_principalprofile_sp;

SELECT * FROM msdb.dbo.sysmail_event_log;