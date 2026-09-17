create schema if not exists equi_landing;

-- Preliminary: 
-- The variables `update_en_equi_worklist`, `easting`, `northing` is set in DuckDb (i.e. not env vars)


-- Set the variables `update_en_equi_worklist`, `easting`, `northing` before running this file

create or replace table equi_landing.worklist as
select 
    t.*
from read_xlsx(
    getvariable('update_en_equi_worklist'),
    all_varchar=true, 
    sheet='Sheet1'
) as t;


-- EASTING
insert into sqlite_db.equi_change_classification by name
select
    1 as batch_number,
    t."Equipment" as equipment,
    'EAST_NORTH' as class,
    'EASTING' as characteristics,
    getvariable('easting') as char_value
from equi_landing.worklist t;


-- NORTHING
insert into sqlite_db.equi_change_classification by name
select
    1 as batch_number,
    t."Equipment" as equipment,
    'EAST_NORTH' as class,
    'NORTHING' as characteristics,
    getvariable('northing') as char_value
from equi_landing.worklist t;

