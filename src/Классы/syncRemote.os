
#Использовать logos
#Использовать gitrunner

Перем ВерсияПлагина;
Перем Лог;
Перем КомандыПлагина;

Перем Обработчик;

Перем URLРепозитория;
Перем ИмяВетки;
Перем ПолучитьИзменения;
Перем ОтправитьИзменения;

Перем КоличествоКоммитовДоPush;
Перем СчетчикКоммитов;
Перем ОтправлятьТеги;

Перем ГитРепозиторий;

#Область Интерфейс_плагина

// Возвращает версию плагина
//
//  Возвращаемое значение:
//   Строка - текущая версия плагина
//
Функция Версия() Экспорт
	Возврат "1.0.5";
КонецФункции

// Возвращает приоритет выполнения плагина
//
//  Возвращаемое значение:
//   Число - приоритет выполнения плагина
//
Функция Приоритет() Экспорт
	Возврат 0;
КонецФункции

// Возвращает описание плагина
//
//  Возвращаемое значение:
//   Строка - описание функциональности плагина
//
Функция Описание() Экспорт
	Возврат "Плагин добавляет функциональность синхронизации с удаленным репозиторием git";
КонецФункции

// Возвращает подробную справку к плагину 
//
//  Возвращаемое значение:
//   Строка - подробная справка для плагина
//
Функция Справка() Экспорт
	Возврат "Справка плагина";
КонецФункции

// Возвращает имя плагина
//
//  Возвращаемое значение:
//   Строка - имя плагина при подключении
//
Функция Имя() Экспорт
	Возврат "sync-remote";
КонецФункции 

// Возвращает имя лога плагина
//
//  Возвращаемое значение:
//   Строка - имя лога плагина
//
Функция ИмяЛога() Экспорт
	Возврат "oscript.lib.gitsync.plugins.sync-remote";
КонецФункции

#КонецОбласти

#Область Подписки_на_события

Процедура ПриАктивизации(СтандартныйОбработчик) Экспорт

	Обработчик = СтандартныйОбработчик;

	URLРепозитория = "";
	ИмяВетки = "";
	ПолучитьИзменения = Ложь;
	ОтправитьИзменения = Ложь;
	ОтправлятьТеги = Ложь;

	КоличествоКоммитовДоPush = 0;
	СчетчикКоммитов = 0;

КонецПроцедуры

Процедура ПриРегистрацииКомандыПриложения(ИмяКоманды, КлассРеализации) Экспорт

	Лог.Отладка("Ищу команду <%1> в списке поддерживаемых", ИмяКоманды);
	Если КомандыПлагина.Найти(ИмяКоманды) = Неопределено Тогда
		Возврат;
	КонецЕсли;

	Лог.Отладка("Устанавливаю дополнительные параметры для команды %1", ИмяКоманды);
	
	//КлассРеализации.Опция("b branch", "master", "<имя ветки git>").ВОкружении("GITSYNC_BRANCH");
	КлассРеализации.Опция("P push", Ложь, "[*sync-remote] Флаг отправки изменений на удаленный репозиторий")
				.Флаг()
				.ВОкружении("GITSYNC_REMOTE_PUSH");
	КлассРеализации.Опция("G pull", Ложь, "[*sync-remote] Флаг получения изменений из удаленный репозитория перед синхронизацией")
				.Флаг()
				.ВОкружении("GITSYNC_REMOTE_PULL");
	КлассРеализации.Опция("T push-tags", Ложь, "[*sync-remote] Флаг отправки тегов по версиям")
				.Флаг()
				.ВОкружении("GITSYNC_REMOTE_PUSH_TAGS");
	КлассРеализации.Опция("n push-n-commits", 0, "[*sync-remote] <число> количество коммитов до промежуточной отправки на удаленный сервер")
				.ТЧисло()
				.ВОкружении("GITSYNC_REMOTE_PUSH_N_COMMITS");

	КлассРеализации.Аргумент("URL", "", "[*sync-remote] Адрес удаленного репозитория GIT.")
				.ВОкружении("GITSYNC_REPO_URL")
				.Обязательный(Ложь);

КонецПроцедуры

Процедура ПриПолученииПараметров(ПараметрыКоманды) Экспорт

	URLРепозитория = ПараметрыКоманды.Параметр("URL", "");
	ИмяВетки = ПараметрыКоманды.Параметр("branch", "");

	ПолучитьИзменения = ПараметрыКоманды.Параметр("pull", Ложь);
	ОтправитьИзменения = ПараметрыКоманды.Параметр("push", Ложь);
	ОтправлятьТеги = ПараметрыКоманды.Параметр("push-tags", Ложь);

	КоличествоКоммитовДоPush = ПараметрыКоманды.Параметр("push-n-commits", 0);

	Лог.Отладка("Установлена отправка изменений <%1> ", ОтправитьИзменения);
	Лог.Отладка("Установлено получение изменений <%1> ", ОтправитьИзменения);
	Лог.Отладка("Установлено количество коммитов <%1> после, которых осуществляется отправка", КоличествоКоммитовДоPush);
	Лог.Отладка("Установлен флаг оправки меток в значение <%1> выгрузки версий", ОтправлятьТеги);

КонецПроцедуры

Процедура ПередНачаломВыполнения(ПутьКХранилищу, КаталогРабочейКопии) Экспорт

	Если Не ПолучитьИзменения Тогда
		Возврат;
	КонецЕсли;

	Лог.Информация("Получение изменений с удаленного узла (pull)");

	ГитРепозиторий = ПолучитьГитРепозиторий(КаталогРабочейКопии);
	ГитРепозиторий.Получить(URLРепозитория, ИмяВетки);

КонецПроцедуры

Процедура ПослеОкончанияВыполнения(ПутьКХранилищу, КаталогРабочейКопии) Экспорт

	Если СчетчикКоммитов = 0 Тогда
		Возврат;
	КонецЕсли;
	
	ГитРепозиторий = ПолучитьГитРепозиторий(КаталогРабочейКопии);
	ВыполнитьGitPush(ГитРепозиторий, КаталогРабочейКопии);

КонецПроцедуры

Процедура ПослеКоммита(ГитРепозиторий, КаталогРабочейКопии) Экспорт

	СчетчикКоммитов = СчетчикКоммитов + 1;

	Если СчетчикКоммитов = КоличествоКоммитовДоPush Тогда

		ВыполнитьGitPush(ГитРепозиторий, КаталогРабочейКопии);
		СчетчикКоммитов = 0;

	КонецЕсли;

КонецПроцедуры

#КонецОбласти

#Область Вспомогательные_процедуры_и_функции

Процедура ВыполнитьGitPush(Знач ГитРепозиторий, Знач ЛокальныйРепозиторий)

	Если Не ОтправитьИзменения Тогда
		Возврат;
	КонецЕсли;

	Лог.Информация("Отправляю изменения на удаленный url (push)");

	ГитРепозиторий.ВыполнитьКоманду(СтрРазделить("gc --auto", " "));
	Лог.Отладка(СтрШаблон("Вывод команды gc: %1", СокрЛП(ГитРепозиторий.ПолучитьВыводКоманды())));

	ПараметрыКомандыPush = Новый Массив;
	ПараметрыКомандыPush.Добавить("push -u");
	ПараметрыКомандыPush.Добавить(СтрЗаменить(URLРепозитория, "%", "%%"));
	ПараметрыКомандыPush.Добавить("-v");

	ГитРепозиторий.ВыполнитьКоманду(ПараметрыКомандыPush);

	Если ОтправлятьТеги Тогда

		ПараметрыКомандыPush = Новый Массив;
		ПараметрыКомандыPush.Добавить("push -u");
		ПараметрыКомандыPush.Добавить(СтрЗаменить(URLРепозитория, "%", "%%"));
		ПараметрыКомандыPush.Добавить("--tags");

		ГитРепозиторий.ВыполнитьКоманду(ПараметрыКомандыPush);

	КонецЕсли;

	Лог.Отладка(СтрШаблон("Вывод команды Push: %1", СокрЛП(ГитРепозиторий.ПолучитьВыводКоманды())));

КонецПроцедуры

Функция ПолучитьГитРепозиторий(Знач КаталогРабочейКопии)
	
	Если Не ГитРепозиторий = Неопределено Тогда
		Возврат ГитРепозиторий;
	КонецЕсли;

	ГитРепозиторий = Новый ГитРепозиторий();
	ГитРепозиторий.УстановитьРабочийКаталог(КаталогРабочейКопии);

	Возврат ГитРепозиторий;

КонецФункции // ПолучитьГитРепозиторий()

Процедура Инициализация()

	ВерсияПлагина = "1.0.0";
	Лог = Логирование.ПолучитьЛог(ИмяЛога());
	КомандыПлагина = Новый Массив;
	КомандыПлагина.Добавить("sync");

	URLРепозитория = "";
	ИмяВетки = "";
	ПолучитьИзменения = Ложь;
	ОтправитьИзменения = Ложь;
	ОтправлятьТеги = Ложь;

	КоличествоКоммитовДоPush = 0;
	СчетчикКоммитов = 0;

КонецПроцедуры

#КонецОбласти

Инициализация();
