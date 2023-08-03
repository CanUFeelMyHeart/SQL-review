create procedure syn.usp_ImportFileCustomerSeasonal
	@ID_Record int
as
set nocount on
begin
	/* 	Ошибка 1.
        Название объекта не отображает цель

		Ошибка 2.
		Declare используем 1 раз.
		Дальнейшее переменные перечисляются 
		через запятую с новой строки, если явно не требуется
		писать declare
		
        Ошибка 7.
		Переменную уместнее назвать "@RowsCount"
		
	*/
    
	declare @RowCount int = (select count(*) from syn.SA_CustomerSeasonal)
	declare @ErrorMessage varchar(max)

-- Проверка на корректность загрузки
	if not exists (
    /* 	
        Ошибка 3.
        Содержимое скобок переносится на следующую строку
	*/
	select 1
	from syn.ImportFile as f
	where f.ID = @ID_Record
		and f.FlagLoaded = cast(1 as bit)
	)
    /* 	
        Ошибка 4. 
		На одном уровне с `if` и `begin/end`
	*/
		begin
			set @ErrorMessage = 'Ошибка при загрузке файла, проверьте корректность данных'

			raiserror(@ErrorMessage, 3, 1)
			return
		end
    -- Ошибка 5. Нет проверки на наличие объекта
	CREATE TABLE #ProcessedRows (
		ActionType varchar(255),
		ID int
	)
	/* 
		Ошибка 6. 
        Между "--"" и комментарием есть один пробел
	*/
	--Чтение из слоя временных данных
	select
		cc.ID as ID_dbo_Customer
		,cst.ID as ID_CustomerSystemType
		,s.ID as ID_Season
		,cast(cs.DateBegin as date) as DateBegin
		,cast(cs.DateEnd as date) as DateEnd
		,cd.ID as ID_dbo_CustomerDistributor
		,cast(isnull(cs.FlagActive, 0) as bit) as FlagActive
	into #CustomerSeasonal
    /*
        Ошибка 8.
        Псевдоним задается через as 
	*/
	from syn.SA_CustomerSeasonal cs
		join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
			and cc.ID_mapping_DataSource = 1
		join dbo.Season as s on s.Name = cs.Season
		join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor
			and cd.ID_mapping_DataSource = 1
		join syn.CustomerSystemType as cst on cs.CustomerSystemType = cst.Name
    -- Ошибка 9. Ключевое слово записано в [ ]
	where try_cast(cs.DateBegin as date) is not null
		and try_cast(cs.DateEnd as date) is not null
		and try_cast(isnull(cs.FlagActive, 0) as bit) is not null
	/* 
        Ошибка 10. 
		Многосточный комментарий задается 
        через " /* текст многострочного комментария */"
	*/

	-- Определяем некорректные записи
	-- Добавляем причину, по которой запись считается некорректной
	select
		cs.*
		,case
        	/*
				Ошибка 11.
				При написании конструкции с case ,
				необходимо, чтобы when был под case с 1 отступом

				Ошибка 12.
				then с 2 отступами, дополнительные условия and с
				3 отступами, для визуального понимания написанных условий
			*/
			when cc.ID is null then 'UID клиента отсутствует в справочнике "Клиент"'
			when cd.ID is null then 'UID дистрибьютора отсутствует в справочнике "Клиент"'
			when s.ID is null then 'Сезон отсутствует в справочнике "Сезон"'
			when cst.ID is null then 'Тип клиента в справочнике "Тип клиента"'
			when try_cast(cs.DateBegin as date) is null then 'Невозможно определить Дату начала'
			when try_cast(cs.DateEnd as date) is null then 'Невозможно определить Дату начала'
			when try_cast(isnull(cs.FlagActive, 0) as bit) is null then 'Невозможно определить Активность'
		end as Reason
	into #BadInsertedRows
	from syn.SA_CustomerSeasonal as cs
	left join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
		and cc.ID_mapping_DataSource = 1
    /* 
        Ошибка 13. 
		Для повышения читаемости кода длинные условия, формулы, выражения и
		т.п., занимающие более ~75% ширины экрана должны быть разделены на
		несколько строк. Каждый параметр с новой строки. Применяется
		выравнивание стеком
	*/
	left join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor and cd.ID_mapping_DataSource = 1
	left join dbo.Season as s on s.Name = cs.Season
	left join syn.CustomerSystemType as cst on cst.Name = cs.CustomerSystemType
	where cc.ID is null
		or cd.ID is null
		or s.ID is null
		or cst.ID is null
		or try_cast(cs.DateBegin as date) is null
		or try_cast(cs.DateEnd as date) is null
		or try_cast(isnull(cs.FlagActive, 0) as bit) is null
		
end
