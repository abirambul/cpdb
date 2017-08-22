
///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Перем Лог;
Перем ИспользуемаяВерсияПлатформы;

// Интерфейсная процедура, выполняет регистрацию команды и настройку парсера командной строки
//   
// Параметры:
//   ИмяКоманды 	- Строка										- Имя регистрируемой команды
//   Парсер 		- ПарсерАргументовКоманднойСтроки (cmdline)		- Парсер командной строки
//
Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Загружает информационную базу из файла");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-params",
		"Файлы JSON содержащие значения параметров,
		|могут быть указаны несколько файлов разделенные "";""
		|(параметры командной строки имеют более высокий приоритет)");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ib-path",
		"Строка подключения к ИБ");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ib-user",
		"Пользователь ИБ");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-ib-pwd",
		"Пароль пользователя ИБ");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-dt-path",
		"Путь к файлу для выгрузки ИБ");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-uccode",
		"Ключ разрешения запуска ИБ");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-delsrc",
		"Удалить файл после загрузки");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
    	"-v8version",
    	"Маска версии платформы 1С");

    Парсер.ДобавитьКоманду(ОписаниеКоманды);

КонецПроцедуры //ЗарегистрироватьКоманду()

// Интерфейсная процедура, выполняет текущую команду
//   
// Параметры:
//   ПараметрыКоманды 	- Соответствие						- Соответствие параметров команды и их значений
//
// Возвращаемое значение:
//	Число - код возврата команды
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
    
	ЗапускПриложений.ПрочитатьПараметрыКомандыИзФайла(ПараметрыКоманды["-params"], ПараметрыКоманды);
	
	СтрокаПодключения			= ПараметрыКоманды["-ib-path"];
	Пользователь				= ПараметрыКоманды["-ib-user"];
	ПарольПользователя			= ПараметрыКоманды["-ib-pwd"];
	ПутьКФайлу					= ПараметрыКоманды["-dt-path"];
	КлючРазрешения				= ПараметрыКоманды["-uccode"];
	УдалитьИсточник				= ПараметрыКоманды["-delsrc"];
	ИспользуемаяВерсияПлатформы	= ПараметрыКоманды["-v8version"];
	
	ВозможныйРезультат = МенеджерКомандПриложения.РезультатыКоманд();

	Если ПустаяСтрока(СтрокаПодключения) Тогда
		Лог.Ошибка("Не указана строка подключения к ИБ");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Если ПустаяСтрока(ПутьКФайлу) Тогда
		Лог.Ошибка("Не указан путь к файлу для выгрузки ИБ");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Попытка
		ВыполнитьЗагрузкуИБ(СтрокаПодключения
						  , ПутьКФайлу
						  , Пользователь
						  , ПарольПользователя
						  , КлючРазрешения);

		Если УдалитьИсточник Тогда
			УдалитьФайлы(ПутьКФайлу);
			Лог.Информация("Исходный файл %1 удален", ПутьКФайлу);
		КонецЕсли;
		
		Возврат ВозможныйРезультат.Успех;
	Исключение
		Лог.Ошибка(ОписаниеОшибки());
		Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
	КонецПопытки;

КонецФункции //ВыполнитьКоманду()

Процедура ВыполнитьЗагрузкуИБ(Знач СтрокаПодключения
							, Знач ПутьФайлу
							, Знач ИмяПользователя
							, Знач ПарольПользователя
							, Знач КлючРазрешения)

	Конфигуратор = ЗапускПриложений.НастроитьКонфигуратор(
														, СтрокаПодключения
														, ИмяПользователя
														, ПарольПользователя
														, ИспользуемаяВерсияПлатформы);
	
	Если Не ПустаяСтрока(КлючРазрешения) Тогда
		Конфигуратор.УстановитьКлючРазрешенияЗапуска(КлючРазрешения);
	КонецЕсли;

	Конфигуратор.ЗагрузитьИнформационнуюБазу(ПутьФайлу);

КонецПроцедуры

Лог = Логирование.ПолучитьЛог("ktb.app.cpdb");