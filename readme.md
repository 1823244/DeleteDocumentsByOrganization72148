зеркало обработки
https://infostart.ru/public/72148/

Описание

Обработка удаления документов с отбором по организации для конфигураций, где есть справочник "Организации" и у документов есть реквизит "Организация".

Успешно протестирована в конфигурациях УТ 10.х и БП 2.х, 3.х.

Описание настроек (для файла УдалениеДокументовПоОрганизации_УТ_БП_82_72148_УФ_фон.epf).

Период. Необязательный. При пустом значении документы выбираются в интервале от 01.01.0001 до 01.01.2999.

Организация. Необязательный. При пустом значении будут удалены все документы.

Непосредственно. При Включенном флажке документы будут удалены физически, при выключенном - помечены на удаление.

ОбменДанными.Загрузка = Истина. Если включен этот режим, то пометка на удаление происходит без проверки остатков товаров и вообще без всяких проверок. Это может привести к тому, что в регистрах останутся движения документов. После завершения работы, нужно запустить ТИИ с очисткой ссылок и пересчитать итоги.

Сдвинуть бух итоги в прошлое. Если указана дата начала, то итоги по регистру Хозрасчетный сдвигаюся на ближайший месяц до этой даты. Если не указана - сдвигаются на 01.01.2001. Настройка применима для конфигураций, где есть регистр бухгалтерии "Хозрасчетный".

Сдвинуть регистры накопления в прошлое. Работа с датами аналогична регистру бухгалтерии. Для оборотных регистров отключается использование итогов или агрегатов. Следует помнить, что если используются агрегаты у оборотных регистров накопления, то они будут очищены при отключении их использования. Агрегаты пока не тестировались. Настройка применима для всех конфигураций.

Ведется логирование. Можно настроить запись лога в текстовый файл и в журнал регистрации.

Примечания.
Для платформ 8.0-8.2 нельзя задать область поиска ссылок при удалении справочников и регистров сведений. Это связано с тем, что у метода НайтиПоСсылкам() нет параметра ВключитьОбъекты (введен в платформе 8.3)