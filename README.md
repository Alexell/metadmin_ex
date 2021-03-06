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
* Исправлена ошибка добавления игрока в БД MySQL
* Добавлена привелегия на срыв пломб, при её отсутствии игроки не смогут срывать пломбы
* Добавлена привелегия для "тихих" нарушений (не будет уведомления в чат и записи в профиль)
* Проезд запрещающего сигнала теперь разделяется приказом на проезд полу-автомата по ПС и подтверждением проезда автомата

### Установка.

* Поместить папку с содержимым репозитория в папку garrysmod\addons.

или

* Добавить в коллекцию сервера: https://steamcommunity.com/sharedfiles/filedetails/?id=1682587784

### Первый запуск сервера с Metadmin.
**1.** Открываете конфиг сервера `garrysmod\cfg\server.cfg` и проверяете чтобы вверху была строчка `rcon_password "любой пароль"`
Если строчки нету - надо добавить.

**2.** Запускаете сервер.

**3.** Запускаете игру, подключаетесь к серверу, открываете консоль в игре и пишете:

сначала:
`rcon_password "пароль из конфига"`

затем:
`rcon ulx setrank "ваш ник" superadmin`

### Первоначальная настройка.
* Если сервер не новый, **не включайте** галочку "Перезапись" в настройках, иначе всех, кто зайдет впервые после установки мода перекинет в группу user.
* **ЗАПРЕТИТЕ** всем пользоваться командами `!adduser` и `!removeuser`, используйте вместо них `!setrank`, иначе ранги не будут выдаваться корректно.
* Создайте в ULX необходимые вам группы
* Создайте и укажите каждой группе Team, для того чтобы в Scoreboard нормально отображалась должность и её цвет.
* В Metadmin отредактируйте ранги в соответствии с группами ULX. Если все сделано правильно - все ранги в списке Metadmin станут зелеными.


### MySQL.
Если вы хотите использовать БД MySQL (актуально для нескольких синхронизируемых серверов), то понадобится сделать следующее:
* создать БД MySQL на каком-нибудь хостинге
* Поместить [это](https://github.com/FredyH/MySQLOO/releases/download/9.5/gmsv_mysqloo_win32.dll) в папку `garrysmod/lua/bin`
* Поместить [это](https://github.com/FredyH/MySQLOO/raw/master/MySQL/lib/windows/libmysql.dll) в КОРНЕВУЮ ДИРЕКТОРИЮ СЕРВЕРА рядом с `srcds.exe`
* запустить сервер Метростроя
* в Metadmin заполнить "Настройки MySQL" данными для подключения к вашей БД, затем переключить sql на mysql
* перезапустить сервер Метростроя

При использовании MySQL, Metadmin хранит свои настройки (включая данные для MySQL подключения) в локальной `sv.db`, а игроков, тесты, ответы игроков, нарушения и прочее хранит в MySQL.
