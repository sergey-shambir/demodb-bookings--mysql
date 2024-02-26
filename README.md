# База данных «Авиаперевозки» для MySQL 8.x

Демонстрационная база данных «Авиаперевозки» выпускается компанией [Postgres Pro](https://postgrespro.ru), разрабатывающей одноимённую российскую СУБД.

- Исходная база данных распространяется под [лицензией PostgreSQL](https://www.postgresql.org/about/licence/)
- Данная версия распространяется под аналогичной пермиссивной лицензией MIT

Страница базы данных (для PostgreSQL): https://postgrespro.ru/docs/postgrespro/10/demodb-bookings

Данный репозиторий содержит версию базы данных «Авиаперевозки» для MySQL версии 8.0 и выше:

- Файл `data/mysql/aviation-mysql-schema.sql` содержит схему БД
- Файл `data/mysql/aviation-mysql-data.sql` содержит дамп данных БД
- Файл `data/mysql/aviation-mysql-drop-tables.sql` содержит команды DROP TABLE для этой БД, что может пригодиться для очистки неудачных попыток импорта

Вы можете использовать docker-compose для экспериментов.

# Импорт данных

## Импорт в Windows

Для Windows вам потребуется распаковать GZIP-архив, что можно сделать с помощью Gzip for Windows: https://gnuwin32.sourceforge.net/packages/gzip.htm

## Вариант 1: без docker-compose

Создайте базу `bookings` и пользователя для неё (например, `sandbox`):

```sql
CREATE DATABASE bookings CHARACTER SET = utf8mb4;

CREATE USER 'sandbox'@'localhost' IDENTIFIED BY 'Придумайте свой пароль';

GRANT ALL PRIVILEGES ON bookings.* TO 'sandbox'@'localhost';
```

После чего можно импортировать схему и данные

```bash
# Распаковка архива с данными
gunzip -c data/mysql/aviation-mysql-data.sql.gz >data/mysql/aviation-mysql-data.sql

# Импорт схемы
mysql -usandbox -pВашПароль bookings <data/mysql/aviation-mysql-schema.sql

# Импорт данных
mysql -usandbox -pВашПароль bookings <data/mysql/aviation-mysql-data.sql

```

## Вариант 2: с использованием docker-compose

Вариант удобен для Linux.

```bash
# Выполнять в отдельной консоли и не останавливать, т.к. запускает сервис MySQL:
docker-compose up

# Импортировать схему базы данных в MySQL
docker exec -i aviation-mysql-db mysql -usandbox -p123s bookings <data/mysql/aviation-mysql-schema.sql

# Импортировать данные базы данных в MySQL
gunzip -c data/mysql/aviation-mysql-data.sql.gz | docker exec -i aviation-mysql-db mysql -usandbox -p123s bookings && echo OK

```

# Технические нюансы

## Отличия от оригинальной версии для PostgreSQL

1. Представления (VIEW) и хранимые функции (FUNCTION) не переносились
2. В таблице `ticket_flights` убран внешний ключ `(ticket_no, flight_id)`: в отличии от PostgreSQL, в MySQL не поддерживаются составные внешние ключи.

## Как был выполнен экспорт данных данных из PostgreSQL в MySQL

Последовательность шагов в Linux:

1. Загрузить архив `demo-medium.zip` со [страницы базы данных «Авиаперевозки»](https://postgrespro.ru/docs/postgrespro/10/demodb-bookings)
2. Распаковать архив, файл demo-medium-20170815.sql переместить в каталог `data/pg/` этого проекта
3. Выполнить команды, указанные ниже

```bash
docker-compose -f docker-compose-postgres.yml up

# Импортировать базу данных в PostgreSQL
docker exec -i aviation-postgres-db psql -U postgres <data/pg/demo-medium-20170815.sql

# В консоли PostgreSQL выполнить:
#   \c demo
#   \dt
docker exec -it aviation-postgres-db psql -U postgres

# Экспортировать базу данных из PostgreSQL
docker exec -i -e PGPASSWORD=postgres aviation-postgres-db pg_dump -U postgres --quote-all-identifiers --no-acl --no-owner --format p --data-only demo >data/pg/exported.sql

docker exec -i -e PGPASSWORD=postgres aviation-postgres-db pg_dump -U postgres --quote-all-identifiers --no-acl --no-owner --format p --schema-only demo >data/pg/exported-schema.sql

# Конвертировать дамп скриптом
php scripts/pg2mysql_cli.php data/pg/exported.sql data/mysql/aviation-mysql-data.sql

# Исправляем огрехи скрипта pg2mysql_cli.php
sed -i 's/INSERT INTO `bookings"."\([a-z_][a-z_]*\)"`/INSERT INTO `\1`/g' data/mysql/aviation-mysql-data.sql
sed -i 's/00+00/00/g' data/mysql/aviation-mysql-data.sql

# Архивируем данные с помощью GZIP
gzip data/mysql/aviation-mysql-data.sql

docker-compose -f docker-compose-postgres.yml down
```
