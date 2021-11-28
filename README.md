# Metadmin Extended

![Metadmin Extended](https://mss.community/images/addons/metadmin_ex.jpg)

### Описание
**Metadmin** - аддон для комфортной и приближенной к реальности игры на серверах Metrostroi. Благодаря этому аддону, вы получаете намного больше информации об игроке (поведение на сервере, нарушения, общую успеваемость, ранг). Это ваша личная база данных о каждом пользователе.

**Metadmin Extended** - расширенная версия Metadmin.

**Список функций Metadmin:**
* Профили игроков
* Повышение и понижение игроков (в истории указывается кто и когда повышал/понижал)
* Выдача/отбирание талонов
* Автоматическая фиксация нарушений (проезд запрещающего сигнала, срыв пломб)
* Нарушения можно добавлять и вручную
* Приказы
* Тесты (создание, редактирование, выдача игрокам, просмотр бланка, проверка и оценка)

**Особенности Metadmin Extended:**
* Исправлена ошибка добавления игрока в БД MySQL (присутствует в оригинальном Metadmin от 16.04.2019)
* Добавлена привелегия на срыв пломб, при её отсутствии игроки не смогут срывать пломбы
* Добавлена привелегия для "тихих" нарушений (не будет уведомления в чат и записи в профиль)
* Проезд запрещающего сигнала теперь разделяется приказом на проезд полу-автомата по ПС и подтверждением проезда автомата

### 1. Установка.

* Добавить в коллекцию сервера: https://steamcommunity.com/sharedfiles/filedetails/?id=1682587784


### 2. Если вы впервые подключаете к серверу Metadmin / Metadmin Extended:
**1.** Открываете конфиг сервера `garrysmod\cfg\server.cfg` и проверяете чтобы вверху была строчка `rcon_password "любой пароль"`
Если строчки нету - надо добавить.

**2.** Запускаете сервер.

**3.** Запускаете игру, подключаетесь к серверу, открываете консоль в игре и пишете:

сначала:
`rcon_password "пароль из конфига"`

затем:
`rcon ulx setrank "ваш ник" superadmin`


Затем rcon можно отключить, если он не нужен. **Обязательно переподключитесь к серверу** и проверьте, чтобы ваша должность superadmin сохранилась и в Metadmin и в ULX.

### 3. Первоначальная настройка.
* Если сервер уже с игроками (т.е. не новый), **не включайте** галочку "Перезапись" в настройках, иначе всех, кто зайдет впервые после установки мода, перекинет в группу user.
* **ЗАПРЕТИТЕ** всем пользоваться командами `!adduser` и `!removeuser`, используйте вместо них `!setrank`, иначе ранги не будут выдаваться корректно.
* Создайте в ULX необходимые вам группы
* Создайте и назначьте каждой группе Team, для того чтобы в Scoreboard нормально отображалась должность и её цвет.
* Не забудьте также назначить всем группам права и доступы к командам в Permissions и настроить корректное наследование прав. Внимательно смотрите права Metadmin.
* В Metadmin отредактируйте ранги в соответствии с группами ULX. Если все сделано правильно - ранги в списке Metadmin станут зелеными.
* В Metadmin тоже есть наследование, необходимое для работы команд "Повысить" или "Понизить", поэтому не забудьте его настроить.

### 4. Если выбран SQL.
Metadmin Extended полностью совместим с Metadmin в этом режиме, т.е. вы можете легко поменять в вашей коллекции Metadmin на Metadmin Extended или наоборот и это не приведет к ошибкам или проблемам.

### 5. Если выбран MySQL.

#### 5.1 Новый сервер.
Если вы хотите использовать БД MySQL (актуально для нескольких синхронизируемых серверов или для вывода информации об игроках на сайт), то понадобится сделать следующее:
* создать БД MySQL на каком-нибудь хостинге
* Скачать [gmsv_mysqloo_win32.dll](https://github.com/FredyH/MySQLOO/releases) и поместить в папку сервера `garrysmod/lua/bin`
* Запустить сервер Метростроя
* В Metadmin заполнить "Настройки MySQL" данными для подключения к вашей БД, затем переключить SQL на MySQL
* Перезапустить сервер Метростроя, убедиться что в БД MySQL автоматически создались таблицы

#### 5.2 Существующий сервер.
Если вы уже использовали Metadmin с БД MySQL, то для перехода на Medatmin Extended необходимо следующее:
* Выключите сервер Метростроя
* Удалите из коллекции Metadmin и добавьте Metadmin Extended
* Зайдите в phpMyAdmin вашей БД MySQL, выберите слева нужную БД (именно саму БД, не нажимайте на таблицы)
* Справа вверху нажмите SQL и вставьте в поле следующие запросы (никакие данные не будут утрачены, просто изменится структура таблиц):

```
-- Сначала делаем все таблицы InnoDB, этот движок новее и быстрее
ALTER TABLE `ma_answers` ENGINE=InnoDB;
ALTER TABLE `ma_examinfo` ENGINE=InnoDB;
ALTER TABLE `ma_players` ENGINE=InnoDB;
ALTER TABLE `ma_questions` ENGINE=InnoDB;
ALTER TABLE `ma_violations` ENGINE=InnoDB;

-- Затем меняем макс. длину полей SID до 25, так как длина 32-битных SteamID выросла
ALTER TABLE `ma_answers` CHANGE `SID` `SID` VARCHAR(25);
ALTER TABLE `ma_examinfo` CHANGE `SID` `SID` VARCHAR(25);
ALTER TABLE `ma_players` CHANGE `SID` `SID` VARCHAR(25);
ALTER TABLE `ma_violations` CHANGE `SID` `SID` VARCHAR(25);

-- Добавляем первым поле ID в таблицу игроков
ALTER TABLE `ma_players` ADD `id` INT NOT NULL AUTO_INCREMENT FIRST, ADD PRIMARY KEY (`id`);
```
* Затем нажмите справа под полем кнопку "Вперед" для выполнения запросов.
* Не должно быть никакиз ошибок при выполнении запросов
* После этого можно запускать сервер Метростроя и наслаждаться Metadmin Extended


**P.S.** При использовании MySQL, Metadmin хранит свои настройки (включая данные для MySQL подключения) в локальной `sv.db`, а игроков, тесты, ответы игроков, нарушения и прочее хранит в MySQL.
