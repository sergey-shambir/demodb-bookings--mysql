/*
 ******************************************************************
 * Преобразование `airports_data.coordinates` к типу данных POINT *
 ******************************************************************
 */

-- Переименование колонки `coordinates` в `text_coordinates` с целью освободить название
ALTER TABLE airports_data
  CHANGE coordinates text_coordinates VARCHAR(1000) NOT NULL
;

-- Добавление новой колонки `coordinates` правильного типа
ALTER TABLE airports_data
  ADD COLUMN coordinates POINT NULL
;

-- Заполнение колонки `coordinates`
UPDATE airports_data
SET coordinates = ST_POINTFROMTEXT(CONCAT('POINT', REPLACE(text_coordinates, ',', ' ')))
WHERE coordinates IS NULL
;

-- Возвращение атрибута NOT NULL, удаление старой колонки
ALTER TABLE airports_data
  MODIFY coordinates POINT NOT NULL,
  DROP COLUMN text_coordinates
;
