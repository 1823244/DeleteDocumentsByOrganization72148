﻿
//Обработчик кнопки "Выполнить"
&НаКлиенте
Процедура ВыполнитьУдаление(Команда)
	
	#Если Не ВебКлиент Тогда
		
		Отказ = Ложь;
		
		ТекстВопроса = "Выполнить удаление документов?";
		
		Если Объект.МодальностьРазрешена Тогда
			КодВыполнения = "
			|Ответ = Вопрос(ТекстВопроса, РежимДиалогаВопрос.ДаНет);
			|ВыполнитьУдалениеЗавершение(Ответ, Отказ);";
		Иначе
			Отказ = Ложь;
			КодВыполнения = "
			|Оповещение = Новый ОписаниеОповещения(""ВыполнитьУдалениеЗавершение"", ЭтаФорма);
			|ПоказатьВопрос(Оповещение, ТекстВопроса, РежимДиалогаВопрос.ДаНет);";
		КонецЕсли;
		
		Выполнить(КодВыполнения);
		
	#КонецЕсли
	
КонецПроцедуры

&НаКлиенте
Процедура ВыполнитьУдалениеЗавершение(Результат, Отказ = Истина) Экспорт
	
	Если Результат = КодВозвратаДиалога.Нет Тогда
		Отказ = Истина;
		Возврат;
	КонецЕсли;
	
	ВыполнитьУдалениеСервер();
	
	ОповеститьОЗавершении();
	
КонецПроцедуры

&НаКлиенте
Процедура ОповеститьОЗавершении()
	
	#Если Не ВебКлиент Тогда
		
		Если Объект.МодальностьРазрешена Тогда
			
			Если ОбменДаннымиЗагрузка = Истина Тогда
				ТекстТИИ = " После удаления запустите Тестирование и Исправление, чтобы очистить движения документов!";
			Иначе
				ТекстТИИ = "";
			КонецЕсли;
			
			КодВыполнения = "
			|Предупреждение(""Удаление завершено!""+ТекстТИИ);";
		Иначе
				
			Если ОбменДаннымиЗагрузка = Истина Тогда
				КодВыполнения = "
				|ПоказатьПредупреждение(,НСтр(""ru = 'Удаление завершено! После удаления запустите Тестирование и Исправление, чтобы очистить движения документов!'; en = 'documents has been deleted! Now you need to run Test and Repair function from Designer'""), 10);";
				
			Иначе
				КодВыполнения = "
				|ПоказатьПредупреждение(,НСтр(""ru = 'Удаление завершено!'; en = 'documents has been deleted!'""), 10);";
			КонецЕсли;
			
		КонецЕсли;
		
		Выполнить(КодВыполнения);
		
	#КонецЕсли
	
КонецПроцедуры

//Основная функция удаления
&НаСервере
Процедура ВыполнитьУдалениеСервер()
	
	тлог = ПолучитьЛог();
	Лог(тлог, "Начали удаление документов");
	
	//сдвиг итогов хозрасчетного
	БухИтогиСдвинуты = Ложь;
	Если Метаданные.РегистрыБухгалтерии.Найти("Хозрасчетный") <> Неопределено Тогда
		Если СдвинутьБухИтогиВПрошлое = Истина Тогда
			Если ЗначениеЗаполнено(Период.ДатаНачала) Тогда
				ДатаИтогов = НачалоМесяца(Период.ДатаНачала)-1;
			Иначе
				ДатаИтогов = '20010101';
			КонецЕсли;
			РегистрыБухгалтерии.Хозрасчетный.УстановитьПериодРассчитанныхИтогов(ДатаИтогов);
			БухИтогиСдвинуты = Истина;
			Лог(тлог, "Включен режим сдвига итогов. БухИтоги сдвинуты на 01.01.2001");
		КонецЕсли;
	КонецЕсли;
	
	//сюда поместим регистры накопления, у которых используются не итоги, а агрегаты, чтобы правильно включить их использование после удаления документов
	СоотвРегистрыНакопленияАгрегаты = Новый Соответствие;
	
	//сдвиг итогов регистров накопления
	РегистрыНакопленияСдвинуты = Ложь;
	Для Каждого Рег Из Метаданные.РегистрыНакопления Цикл
		Если СдвинутьРегистрыНакопленияВПрошлое = Истина Тогда
			Если ЗначениеЗаполнено(Период.ДатаНачала) Тогда
				ДатаИтогов = НачалоМесяца(Период.ДатаНачала)-1;
			Иначе
				ДатаИтогов = '20010101';
			КонецЕсли;
			

			Если Строка(Метаданные.РегистрыНакопления[Рег.Имя].ВидРегистра) = "Остатки" Тогда //почему-то ругается на ВидРегистраНакопления.Остатки...
				РегистрыНакопления[Рег.Имя].УстановитьПериодРассчитанныхИтогов(ДатаИтогов);
				Лог(тлог, "Включен режим сдвига итогов. Отключены итоги регистра накопления "+РегистрыНакопления[Рег.Имя]+". Период итогов "+Строка(ДатаИтогов));
			Иначе
				//запомним регистры оборотов с агрегатами
				Если РегистрыНакопления[Рег.Имя].ПолучитьРежимАгрегатов() = Истина Тогда
					СоотвРегистрыНакопленияАгрегаты.Вставить(Рег.Имя, Истина);
				КонецЕсли;
				Если СоотвРегистрыНакопленияАгрегаты.Получить(Рег.Имя) = Неопределено Тогда
					РегистрыНакопления[Рег.Имя].УстановитьИспользованиеИтогов(Ложь);
					Лог(тлог, "Включен режим сдвига итогов. Отключены итоги регистра накопления "+РегистрыНакопления[Рег.Имя]);
				Иначе
					РегистрыНакопления[Рег.Имя].УстановитьИспользованиеАгрегатов (Ложь);
					Лог(тлог, "Включен режим сдвига итогов. Отключены агрегаты регистра накопления "+РегистрыНакопления[Рег.Имя]);
				КонецЕсли;
			КонецЕсли;
			РегистрыНакопленияСдвинуты = Истина;
		КонецЕсли;
	КонецЦикла;
	
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("ДатаНач", Период.ДатаНачала);
	Запрос.УстановитьПараметр("ДатаКон", ?(ЗначениеЗаполнено(Период.ДатаОкончания), Период.ДатаОкончания, '29990101'));
	Запрос.УстановитьПараметр("Организация", Организация);
	
	//доделать сдвиг бухитогов
	Для Каждого Д из Метаданные.Документы Цикл
		
		Если Д.Реквизиты.Найти("Организация")=Неопределено Тогда
			Продолжить;
		КонецЕсли;
		
		РазрешеноСтавитьПометкуНаУдаление = ПравоДоступа("ИнтерактивнаяПометкаУдаления", Метаданные.Документы[Д.Имя]);
		Если НЕ Непосредственно И Не РазрешеноСтавитьПометкуНаУдаление Тогда
			//добавить вывод в лог
			ЗаписьЖурналаРегистрации("Удаление документов", УровеньЖурналаРегистрации.Информация,,,"Нет прав на пометку удаления: "+строка(Д.Имя));
			Лог(тлог, "Нет прав на пометку удаления: "+строка(Д.Имя));
			Продолжить;
		КонецЕсли;
		
		РазрешеноУдалятьНепосредственно = ПравоДоступа("ИнтерактивноеУдаление", Метаданные.Документы[Д.Имя]);
		Если Непосредственно И Не РазрешеноУдалятьНепосредственно Тогда
			//добавить вывод в лог
			ЗаписьЖурналаРегистрации("Удаление документов", УровеньЖурналаРегистрации.Информация,,,"Нет прав на интерактивное удаление: "+строка(Д.Имя));
			Лог(тлог, "Нет прав на интерактивное удаление: "+строка(Д.Имя));
			Продолжить;
		КонецЕсли;
		
		//ну да, запрос в цикле, а что делать :)
		Запрос.Текст = 
		"ВЫБРАТЬ
		|	Док.Ссылка КАК Ссылка,
		|	1 КАК СсылкаПредставление
		|ИЗ
		|	Документ.АвансовыйОтчет КАК Док
		|ГДЕ
		|	Док.Дата МЕЖДУ &ДатаНач И &ДатаКон
		|	И &УсловиеУдален
		|	И &УсловиеОрганизация
		|
		|УПОРЯДОЧИТЬ ПО
		|	Док.Дата";
		
		Если ЗначениеЗаполнено(Организация) Тогда
			Запрос.Текст = СтрЗаменить(Запрос.Текст, "&УсловиеОрганизация", "Док.Организация = &Организация");
		Иначе
			Запрос.Текст = СтрЗаменить(Запрос.Текст, "&УсловиеОрганизация", "ИСТИНА");
		КонецЕсли;
		
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "1 КАК", "ПРЕДСТАВЛЕНИЕ(Док.Ссылка) КАК");
		Если Непосредственно Тогда
			Запрос.Текст = СтрЗаменить(Запрос.Текст, "&УсловиеУдален", "ИСТИНА");
		Иначе
			Запрос.Текст = СтрЗаменить(Запрос.Текст, "&УсловиеУдален", "Док.ПометкаУдаления = ЛОЖЬ");
		КонецЕсли;
		
		//Это чтобы можно быть текст запрос открывать в конструкторе
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "АвансовыйОтчет", Д.Имя);
		
		Рез = Запрос.Выполнить();
		Если Рез.Пустой() Тогда
			Продолжить;
		КонецЕсли;
		
		Если НЕ ИспользоватьФоновыеЗадания Тогда
			
			//документы
			Выборка = Рез.Выбрать();
			Пока Выборка.Следующий() Цикл
				
				//добавить вывод в лог
				
				ъ = Выборка.Ссылка.ПолучитьОбъект();
				
				Если ОбменДаннымиЗагрузка = Истина Тогда
					ъ.ОбменДанными.Загрузка = Истина;
				КонецЕсли;
				
				Если Непосредственно Тогда
					ЗаписьЖурналаРегистрации("Удаление документов", УровеньЖурналаРегистрации.Информация,,,"Удален непосредственно: "+строка(Выборка.СсылкаПредставление));
					Лог(тлог, "Удален непосредственно: "+строка(Выборка.СсылкаПредставление));
					ъ.Удалить();
				Иначе	
					
					Если ОбменДаннымиЗагрузка = Истина Тогда
						ъ.ПометкаУдаления = Истина;
						ъ.Проведен = Ложь;
						ъ.Записать();
					Иначе
						ъ.УстановитьПометкуУдаления(Истина);
					КонецЕсли;
					
					ЗаписьЖурналаРегистрации("Удаление документов", УровеньЖурналаРегистрации.Информация,,Выборка.Ссылка,"Помечен на удаление");
					Лог(тлог, "Помечен на удаление: "+строка(Выборка.СсылкаПредставление));
					
				КонецЕсли;	
				
			КонецЦикла;
			
			//договоры
			
			
		Иначе
			//28 05 16
			
			//фоновые задания. надо провести ревизию кода и доделать
			
			//НЗ = 1;
			//
			//ЭтоСервер = ?(Найти(СтрокаСоединенияИнформационнойБазы(), "Srvr")=0,Ложь,Истина);
			//
			//т = Новый ТаблицаЗначений;
			//т.Колонки.Добавить("Ссылка");
			//
			//Выборка = Рез.Выбрать();
			//ф = Выборка.Следующий();
			//Пока ф Цикл
			//	
			//	м = 0;
			//	т.Очистить();
			//	
			//	Пока ф И м <= КоличествоДокументовВПакете Цикл
			//		й 			= т.Добавить();
			//		й.Ссылка 	= Выборка.Ссылка;
			//		ф = Выборка.Следующий();
			//	КонецЦикла;
			//	
			//	Если ЭтоСервер Тогда
			//		
			//		МПараметры = Новый Массив;
			//		МПараметры.Добавить(т);
			//		МПараметры.Добавить(НЗ);
			//		МПараметры.Добавить(Непосредственно);
			//		
			//		ЗапуститьВФоне("_Имя_Общего_Модуля_.ВыполнитьУдалениеСервер_Фон", МПараметры, ф);
			//		
			//		НЗ = НЗ + 1; 
			//	Иначе
			//		//если данная процедура будет вызываться из общего модуля, то следует дописать имя общего модуля впереди.
			//		//можно оставить вызов из этого модуля, но тогда следует помнить, что существует 2 одинаковых процедуры
			//		//и при внесении изменений в одну, также модифицировать и другую, чтобы не допускать различий в алгоритме.
			//		ВыполнитьУдалениеСервер_Фон(т, НЗ, Непосредственно);
			//	КонецЕсли;
			//	
			//КонецЦикла;	
			
		КонецЕсли;
		
	КонецЦикла;	 //по документам из метаданных
	
	Если БухИтогиСдвинуты = Истина Тогда
		РегистрыБухгалтерии.Хозрасчетный.УстановитьПериодРассчитанныхИтогов(НачалоМесяца(ТекущаяДата())-1);
		БухИтогиСдвинуты = Ложь;
		Лог(тлог, "Включен режим сдвига итогов. БухИтоги сдвинуты на "+строка(НачалоМесяца(ТекущаяДата())-1));
	КонецЕсли;

	Если РегистрыНакопленияСдвинуты = Истина Тогда
		Для Каждого Рег Из Метаданные.РегистрыНакопления Цикл
			
			Если Строка(Метаданные.РегистрыНакопления[Рег.Имя].ВидРегистра) = "Остатки" Тогда //почему-то ругается на ВидРегистраНакопления.Остатки...
				РегистрыНакопления[Рег.Имя].УстановитьПериодРассчитанныхИтогов(НачалоМесяца(ТекущаяДата())-1);
				Лог(тлог, "Включен режим сдвига итогов. Включены итоги регистра накопления "+РегистрыНакопления[Рег.Имя]+". Период итогов "+Строка(НачалоМесяца(ТекущаяДата())-1));
			Иначе
				
				Если СоотвРегистрыНакопленияАгрегаты.Получить(Рег.Имя) = Неопределено Тогда
					РегистрыНакопления[Рег.Имя].УстановитьИспользованиеИтогов(Истина);
					Лог(тлог, "Включен режим сдвига итогов. Включены итоги регистра накопления "+РегистрыНакопления[Рег.Имя]);
				Иначе
					РегистрыНакопления[Рег.Имя].УстановитьИспользованиеАгрегатов (Истина);
					Лог(тлог, "Включен режим сдвига итогов. Включены агрегаты регистра накопления "+РегистрыНакопления[Рег.Имя]);
				КонецЕсли;
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;
	
КонецПроцедуры

//эту процедуру следует поместить в серверный общий модуль
//Параметры
//	НЗ - число - номер задания
&НаСервере
Процедура ВыполнитьУдалениеСервер_Фон(т, НЗ, Непосредственно)
	
	Для Каждого стр Из т Цикл
		
		ъ = стр.Ссылка.ПолучитьОбъект();
		
		Если Непосредственно Тогда
			ъ.Удалить();
		Иначе	
			ъ.УстановитьПометкуУдаления(Истина);
		КонецЕсли;	
		
	КонецЦикла;
	
КонецПроцедуры

&НаСервере
Процедура ЗапуститьВФоне(ИмяМетода, МПараметры, ф)
	
	Попытка
		МассивЗаданий = ФоновыеЗадания.ПолучитьФоновыеЗадания(Новый Структура("ИмяМетода,Состояние", ИмяМетода, СостояниеФоновогоЗадания.Активно));
	Исключение
		МассивЗаданий = Новый Массив;
	КонецПопытки;
	
	Задание = ФоновыеЗадания.Выполнить(ИмяМетода, МПараметры, Неопределено, "Удаление документов в фоне. infostart.ru № 72148");
	
	МассивЗаданий.Добавить(Задание);
		
	Если (МассивЗаданий.Количество() >= КоличествоОдновременныхПроцессов) ИЛИ (НЕ ф) Тогда
		ФоновыеЗадания.ОжидатьЗавершения(МассивЗаданий);
		МассивЗаданий.Очистить();
	КонецЕсли;
	
КонецПроцедуры







//Интерфейс



&НаКлиенте
Процедура ПриОткрытии(Отказ)
	ЭтоСервер = ?(Найти(СтрокаСоединенияИнформационнойБазы(), "Srvr")=0,Ложь,Истина);
	Если НЕ ЭтоСервер Тогда
		Элементы.ИспользоватьФоновыеЗадания.Видимость = Ложь;
		Элементы.КоличествоОдновременныхПроцессов.Видимость = Ложь;
		Элементы.КоличествоДокументовВПакете.Видимость = Ложь;
	КонецЕсли;
	
	
КонецПроцедуры

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	Об = РеквизитФормыВЗначение("Объект");
	
	СисИнфо = Новый СистемнаяИнформация;
	Объект.ВерсияПриложения = СисИнфо.ВерсияПриложения;
	
	Если Лев(Объект.ВерсияПриложения, 3) = "8.2" Тогда
		Объект.МодальностьРазрешена = Истина;
	Иначе
		Выполнить("Объект.МодальностьРазрешена = Метаданные.РежимИспользованияМодальности = Метаданные.СвойстваОбъектов.РежимИспользованияМодальности.Использовать;");
	КонецЕсли;
	
	ПолноеИмяФайла = РеквизитФормыВЗначение("Объект").ИспользуемоеИмяФайла;
	
	мСтроки = РазложитьСтрокуВМассивПодстрок(ПолноеИмяФайла, "\");
	если ложь тогда мСтроки = Новый Массив; КонецЕсли;
	//получим имя каталога
	ИмяКаталога = ""; 
	Для сч = 0 по мСтроки.Количество() - 2 Цикл
		ИмяКаталога = ИмяКаталога + мСтроки.Получить(сч)+"\";
	КонецЦикла;
	
	//Сообщить(ИмяКаталога);
	ЭтотОбъект.ИмяФайлаЛога = ИмяКаталога + "лог_удаления_"+формат(ТекущаяДата(), "ДФ=ддММгггг")+".txt";
	
	тлог = ПолучитьЛог();
	
	Лог(тлог, "----------------------------------------------------");
	Лог(тлог, "----------------------------------------------------");
	Лог(тлог, "Открыта обработка удаления объектов по организации");
	
КонецПроцедуры

//Лог

Функция Лог(тлог, сообщение)
	
	если ложь тогда тлог = новый записьТекста; КонецЕсли;
	
	стрЛог = Формат(ТекущаяДата(),"ДФ=ддММгггг чч:мм:сс") + " " + сообщение;
	
	попытка
		тлог.ЗаписатьСтроку(стрЛог);
	исключение
		тлог = ПолучитьЛог();
		тлог.ЗаписатьСтроку(стрЛог);
	КонецПопытки;
	
КонецФункции

Функция ПолучитьЛог()
	мФайлы = НайтиФайлы(ЭтотОбъект.ИмяФайлаЛога); 
	Если мФайлы.Количество() = 0 Тогда
		тлог = Новый ЗаписьТекста(ЭтотОбъект.ИмяФайлаЛога, КодировкаТекста.ANSI);
	Иначе
		тлог = Новый ЗаписьТекста();
		тлог.Открыть(ЭтотОбъект.ИмяФайлаЛога,КодировкаТекста.ANSI,,Истина);
	КонецЕсли;
	Возврат тлог;
КонецФункции

//Из БСП

// Разбивает строку на несколько строк по указанному разделителю. Разделитель может иметь любую длину.
// В случаях, когда разделителем является строка из одного символа, и не используется параметр СокращатьНепечатаемыеСимволы,
// рекомендуется использовать функцию платформы СтрРазделить.
//
// Параметры:
//  Значение               - Строка - текст с разделителями;
//  Разделитель            - Строка - разделитель строк текста, минимум 1 символ;
//  ПропускатьПустыеСтроки - Булево - признак необходимости включения в результат пустых строк.
//    Если параметр не задан, то функция работает в режиме совместимости со своей предыдущей версией:
//     - для разделителя-пробела пустые строки не включаются в результат, для остальных разделителей пустые строки
//       включаются в результат.
//     - если параметр Строка не содержит значащих символов или не содержит ни одного символа (пустая строка), то в
//       случае разделителя-пробела результатом функции будет массив, содержащий одно значение "" (пустая строка), а
//       при других разделителях результатом функции будет пустой массив.
//  СокращатьНепечатаемыеСимволы - Булево - сокращать непечатаемые символы по краям каждой из найденных подстрок.
//
// Возвращаемое значение:
//  Массив - массив строк.
//
// Пример:
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок(",один,,два,", ",")
//  - возвратит массив из 5 элементов, три из которых  - пустые: "", "один", "", "два", "";
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок(",один,,два,", ",", Истина)
//  - возвратит массив из двух элементов: "один", "два";
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок(" один   два  ", " ")
//  - возвратит массив из двух элементов: "один", "два";
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок("")
//  - возвратит пустой массив;
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок("",,Ложь)
//  - возвратит массив с одним элементом: ""(пустая строка);
//  СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок("", " ")
//  - возвратит массив с одним элементом: "" (пустая строка).
//
Функция РазложитьСтрокуВМассивПодстрок(Знач Значение, Знач Разделитель = ",", Знач ПропускатьПустыеСтроки = Неопределено, 
	СокращатьНепечатаемыеСимволы = Ложь)
	
	Результат = Новый Массив;
	
	// Для обеспечения обратной совместимости.
	Если ПропускатьПустыеСтроки = Неопределено Тогда
		ПропускатьПустыеСтроки = ?(Разделитель = " ", Истина, Ложь);
		Если ПустаяСтрока(Значение) Тогда 
			Если Разделитель = " " Тогда
				Результат.Добавить("");
			КонецЕсли;
			Возврат Результат;
		КонецЕсли;
	КонецЕсли;
	//
	
	Позиция = СтрНайти(Значение, Разделитель);
	Пока Позиция > 0 Цикл
		Подстрока = Лев(Значение, Позиция - 1);
		Если Не ПропускатьПустыеСтроки Или Не ПустаяСтрока(Подстрока) Тогда
			Если СокращатьНепечатаемыеСимволы Тогда
				Результат.Добавить(СокрЛП(Подстрока));
			Иначе
				Результат.Добавить(Подстрока);
			КонецЕсли;
		КонецЕсли;
		Значение = Сред(Значение, Позиция + СтрДлина(Разделитель));
		Позиция = СтрНайти(Значение, Разделитель);
	КонецЦикла;
	
	Если Не ПропускатьПустыеСтроки Или Не ПустаяСтрока(Значение) Тогда
		Если СокращатьНепечатаемыеСимволы Тогда
			Результат.Добавить(СокрЛП(Значение));
		Иначе
			Результат.Добавить(Значение);
		КонецЕсли;
	КонецЕсли;
	
	Возврат Результат;
	
КонецФункции 

//	Регистры сведений

&НаКлиенте
Процедура УдалитьРегистрыСведений(Команда)
	
	
	#Если Не ВебКлиент Тогда
		
		Отказ = Ложь;
		
		ТекстВопроса = "Выполнить удаление регистров сведений?";
		
		Если Объект.МодальностьРазрешена Тогда
			КодВыполнения = "
			|Ответ = Вопрос(ТекстВопроса, РежимДиалогаВопрос.ДаНет);
			|ВыполнитьУдалениеРегистровСведенийЗавершение(Ответ, Отказ);";
		Иначе
			Отказ = Ложь;
			КодВыполнения = "
			|Оповещение = Новый ОписаниеОповещения(""ВыполнитьУдалениеРегистровСведенийЗавершение"", ЭтаФорма);
			|ПоказатьВопрос(Оповещение, ТекстВопроса, РежимДиалогаВопрос.ДаНет);";
		КонецЕсли;
		
		Выполнить(КодВыполнения);
		
	#КонецЕсли
	
КонецПроцедуры

&НаКлиенте
Процедура ВыполнитьУдалениеРегистровСведенийЗавершение(Результат, Отказ = Истина) Экспорт
	
	Если Результат = КодВозвратаДиалога.Нет Тогда
		Отказ = Истина;
		Возврат;
	КонецЕсли;
	
	УдалитьРегистрыСведенийСервер();
	
	ОповеститьОЗавершенииРегистрыСведений();
	
КонецПроцедуры

&НаКлиенте
Процедура ОповеститьОЗавершенииРегистрыСведений()
	
	#Если Не ВебКлиент Тогда
		
		Если Объект.МодальностьРазрешена Тогда
			
			ТекстТИИ = "";
			
			КодВыполнения = "
			|Предупреждение(""Очистка регистров сведений завершена!""+ТекстТИИ);";
		Иначе
				
			КодВыполнения = "
			|ПоказатьПредупреждение(,НСтр(""ru = 'Очистка регистров сведений завершена!'; en = 'information registers has been cleaned!'""), 10);";
			
		КонецЕсли;
		
		Выполнить(КодВыполнения);
		
	#КонецЕсли
	
КонецПроцедуры

&НаСервере
Процедура УдалитьРегистрыСведенийСервер()
	
	тлог = ПолучитьЛог();
	Лог(тлог, "Начали удаление регистров сведений");
	
	мОрганизации = Новый Массив;
	мОрганизации.Добавить(Организация);
	
	мВключитьОбъекты = Новый Массив;
	Для сч = 0 По Метаданные.РегистрыСведений.Количество()-1 Цикл
		мВключитьОбъекты.Добавить(Метаданные.РегистрыСведений.Получить(сч));
	КонецЦикла;
	
	
	тзСсылки = НайтиПоСсылкам(мОрганизации, Новый Массив, мВключитьОбъекты, Новый Массив);
	
	
	тзСсылки.Свернуть("Метаданные","");
	
	Для Каждого МД из тзСсылки Цикл
		
		НаборЗаписей = РегистрыСведений[МД.Метаданные.Имя].СоздатьНаборЗаписей();
		попытка
			НаборЗаписей.Отбор.Организация.Установить(Организация);
			НаборЗаписей.Записать();
			Лог(тлог, "Организация "+строка(Организация)+" удалена из регистра сведений "+МД.Метаданные.Имя);
		Исключение
			Лог(тлог, "В регистре сведений "+МД.Метаданные.Имя+" нет измерения Организация");
			
			Для Каждого Изм из МД.Метаданные.Измерения Цикл
				Если Изм.Тип.СодержитТип(Тип("СправочникСсылка.Организации")) Тогда
					Лог(тлог, "В регистре сведений "+МД.Метаданные.Имя+" измерение "+Изм.Имя+" содержит тип СправочникСсылка.Организации");
					НаборЗаписей.Отбор[Изм.Имя].Установить(Организация);
					НаборЗаписей.Записать();
					Лог(тлог, "		Организация "+строка(Организация)+" удалена из регистра сведений "+МД.Метаданные.Имя);
				КонецЕсли;
			КонецЦикла;
			
		КонецПопытки;
		
	КонецЦикла;
	
КонецПроцедуры


//	Справочники


&НаКлиенте
Процедура УдалитьСправочники(Команда)
	
	
	#Если Не ВебКлиент Тогда
		
		Отказ = Ложь;
		
		ТекстВопроса = "Выполнить удаление справочников?";
		
		Если Объект.МодальностьРазрешена Тогда
			КодВыполнения = "
			|Ответ = Вопрос(ТекстВопроса, РежимДиалогаВопрос.ДаНет);
			|ВыполнитьУдалениеСправочниковЗавершение(Ответ, Отказ);";
		Иначе
			Отказ = Ложь;
			КодВыполнения = "
			|Оповещение = Новый ОписаниеОповещения(""ВыполнитьУдалениеСправочниковЗавершение"", ЭтаФорма);
			|ПоказатьВопрос(Оповещение, ТекстВопроса, РежимДиалогаВопрос.ДаНет);";
		КонецЕсли;
		
		Выполнить(КодВыполнения);
		
	#КонецЕсли
	
КонецПроцедуры

&НаКлиенте
Процедура ВыполнитьУдалениеСправочниковЗавершение(Результат, Отказ = Истина) Экспорт
	
	Если Результат = КодВозвратаДиалога.Нет Тогда
		Отказ = Истина;
		Возврат;
	КонецЕсли;
	
	УдалитьСправочникиСервер();
	
	ОповеститьОЗавершенииСправочники();
	
КонецПроцедуры

&НаКлиенте
Процедура ОповеститьОЗавершенииСправочники()
	
	#Если Не ВебКлиент Тогда
		
		Если Объект.МодальностьРазрешена Тогда
			
			ТекстТИИ = "";
			
			КодВыполнения = "
			|Предупреждение(""Очистка справочников завершена!""+ТекстТИИ);";
		Иначе
				
			КодВыполнения = "
			|ПоказатьПредупреждение(,НСтр(""ru = 'Очистка справочников завершена!'; en = 'Catalogs has been cleaned!'""), 10);";
			
		КонецЕсли;
		
		Выполнить(КодВыполнения);
		
	#КонецЕсли
	
КонецПроцедуры

&НаСервере
Процедура УдалитьСправочникиСервер()
	
	тлог = ПолучитьЛог();
	Лог(тлог, "Начали удаление справочников");
	
	мОрганизации = Новый Массив;
	мОрганизации.Добавить(Организация);
	
	мВключитьОбъекты = Новый Массив;
	Для сч = 0 По Метаданные.Справочники.Количество()-1 Цикл
		мВключитьОбъекты.Добавить(Метаданные.Справочники.Получить(сч));
	КонецЦикла;
	
	
	тзСсылки = НайтиПоСсылкам(мОрганизации, Новый Массив, мВключитьОбъекты, Новый Массив);
	
	Для Каждого МД из тзСсылки Цикл
		
		РазрешеноСтавитьПометкуНаУдаление = ПравоДоступа("ИнтерактивнаяПометкаУдаления", Метаданные.Справочники[МД.Метаданные.Имя]);
		Если НЕ Непосредственно И Не РазрешеноСтавитьПометкуНаУдаление Тогда
			//добавить вывод в лог
			ЗаписьЖурналаРегистрации("Удаление справочников", УровеньЖурналаРегистрации.Информация,,,"Нет прав на пометку удаления: "+МД.Метаданные.Имя);
			Лог(тлог, "Нет прав на пометку удаления: "+МД.Метаданные.Имя);
			Продолжить;
		КонецЕсли;
		
		РазрешеноУдалятьНепосредственно = ПравоДоступа("ИнтерактивноеУдаление", Метаданные.Справочники[МД.Метаданные.Имя]);
		Если Непосредственно И Не РазрешеноУдалятьНепосредственно Тогда
			//добавить вывод в лог
			ЗаписьЖурналаРегистрации("Удаление справочников", УровеньЖурналаРегистрации.Информация,,,"Нет прав на интерактивное удаление: "+МД.Метаданные.Имя);
			Лог(тлог, "Нет прав на интерактивное удаление: "+МД.Метаданные.Имя);
			Продолжить;
		КонецЕсли;		
		

		ъ = МД.Данные.ПолучитьОбъект();
		
		Если ОбменДаннымиЗагрузка = Истина Тогда
			ъ.ОбменДанными.Загрузка = Истина;
		КонецЕсли;
		
		ПредставлениеОбъекта = строка(МД.Данные);
		Если Непосредственно Тогда
			
			ЗаписьЖурналаРегистрации("Удаление справочников", УровеньЖурналаРегистрации.Информация,,,"Удален непосредственно: "+ПредставлениеОбъекта);
			Лог(тлог, "Удален непосредственно: "+ПредставлениеОбъекта);
			ъ.Удалить();
		Иначе	
			
			Попытка
				Если ОбменДаннымиЗагрузка = Истина Тогда
					ъ.ПометкаУдаления = Истина;
					ъ.Записать();
				Иначе
					ъ.УстановитьПометкуУдаления(Истина);
				КонецЕсли;
				
				ЗаписьЖурналаРегистрации("Удаление справочников", УровеньЖурналаРегистрации.Информация,,МД.Данные,"Помечен на удаление");
				Лог(тлог, "Помечен на удаление: "+ПредставлениеОбъекта);
				
			Исключение
				ОпОшибки = ОписаниеОшибки();
				тОшибки = "Не удалось удалить "+ПредставлениеОбъекта+" по причине "+ОпОшибки;
				ЗаписьЖурналаРегистрации("Удаление справочников", УровеньЖурналаРегистрации.Информация,,МД.Данные,тОшибки);
				Лог(тлог, тОшибки);
			КонецПопытки;
			
		КонецЕсли;			
		
	КонецЦикла;
	
КонецПроцедуры

