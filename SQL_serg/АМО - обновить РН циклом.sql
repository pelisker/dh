	DECLARE 
		@object int,
		@ClientID int,
		@ClientCode int,
		@Leadid int,
		@leadIntId int,
		@managerID int,
		@json varchar(max),
		@type_doc varchar(4),
		@link int,
		@rncode int,
		@SMOcode int,
		@result int,
		@status_id int,
		@lead AmoType 

	
	--1. Поиск Счета
	--SELECT top 1 @SMOcode=code FROM uchet.dbo.doc_ref (NOLOCK) WHERE type_doc='Р/Н+' and date>'01.10.17'
	
	exec AmoAuth @object OUT

	DECLARE rn_cursor CURSOR FOR 
	SELECT rn.code, rn.link FROM uchet.dbo.doc_ref rn (NOLOCK) INNER JOIN uchet.dbo.doc_ref sc (NOLOCK) ON rn.link=sc.code AND sc.type_doc like 'СМо%' WHERE rn.link!=0 AND rn.type_doc='Р/Н+' 
	and rn.date between 
	'01.12.17' AND 
	'06.12.17' ORDER BY rn.date
	OPEN rn_cursor;

	FETCH NEXT FROM rn_cursor 
	INTO @rncode, @link

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @SMOcode=null
		
		SELECT @SMOcode=sc.code FROM uchet.dbo.doc_ref sc (NOLOCK) WHERE sc.code=@link AND sc.type_doc like 'СМо%'
		
		--Если для расходной накладной не найден счет
		IF ISNULL(@SMOcode,0)=0
		BEGIN
			SET @result=-7
			PRINT 'Не найден счет для РН'
		END
		ELSE
		BEGIN
		
			--2. Поиск сделки в АМО
			--Получение amoID
			SELECT @Leadid=amoID FROM uchet.dbo.drforder (NOLOCK) WHERE upcode=@SMOcode
			
			--Если у счета нет amoID
			IF ISNULL(@Leadid,0)=0
			BEGIN
				SET @result=-8
				PRINT 'Счет в СВ не привязан к сделке в АМО. Нет amoID'
				--GOTO NOTOK
			END
			ELSE
			BEGIN
				exec AmoGetLead @object,'',0,0,'',@Leadid,'','',@json out
				INSERT INTO @Lead
				select * from AmoParseJson(@json) WHERE name IN ('status_id') and value not in (142,143)
				
				IF exists(select * from AmoParseJson(@json) WHERE name IN ('status_id') and value not in (142,143))
				BEGIN
				--	update uchet.dbo.doc_ref_sync set error=0, ok=0 where code=@rncode
					select @status_id=CAST(value AS int) from @Lead WHERE name='status_id'
					
					exec @result=integration.dbo.SvAmoSyncLeadsToAmo @rncode,0
					select lead=@Leadid, rncode=@rncode, result=@result, statusid=@status_id
				END
			END
		END

		FETCH NEXT FROM rn_cursor 
		INTO @rncode, @link
	END
	CLOSE rn_cursor;
	DEALLOCATE rn_cursor;

	--17208760 - Передал логисту Москва
	--11736709 - Передал логисту 
	--11995716 - Пути
	--13440198 - В работе
	--12470157 - ждем поставку
	--12041688 - отправил счет на оплату
	--15901201 - отправлен из ПВЗ
	
	
	select * from @lead where name='status_id'
