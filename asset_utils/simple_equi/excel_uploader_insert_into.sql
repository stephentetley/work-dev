--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--


-- Preliminaries: 
-- Must have a sqlite database attached called `sqlite_db` (read-write)
-- and `asset_facts` and `asset_lib` DuckDB catalogs attached as read only
-- The variables `simple_equi_parquet` is set in DuckDB 
-- (i.e. not an env var)
--
-- Run from DuckDB - no need for standalone SQLite is installed 
-- 

.bail on

with cte1_variables as (
select 
    ifnull(getvariable('simple_equi_parquet'), error('Must set variable "simple_equi_parquet"')) as simple_equi_parquet,
)
unpivot cte1_variables
on columns(*)
into name variable value value;

with cte1_databases as (
select 
    if(exists (from duckdb_databases() where database_name = 'sqlite_db'), 
        true, 
        error('Must attach database "sqlite_db"')) as sqlite_db,
    if(exists (from duckdb_databases() where database_name = 'asset_facts'), 
        true, 
        error('Must attach database "asset_facts"')) as asset_facts,
    if(exists (from duckdb_databases() where database_name = 'asset_lib'), 
        true, 
        error('Must attach database "asset_lib"')) as asset_lib,
)
unpivot cte1_databases
on columns(*)
into name database value loaded;


insert into sqlite_db.equi_create_equipment_data by name
select
    t.batch_number as batch_number,
    t.temp_id as equipment,
    t.equi_category as equip_category,
    t.equi_name as description_medium,
    t.equi_type as object_type,
    if(t.weight_kg is not null, format('{:.2f}', t.weight_kg), null) as gross_weight,
    if(t.weight_kg is not null, 'KG', null) as unit_of_weight,
    strftime(t.startup_date, '%d.%m.%Y') as start_up_date,
    t.manufacturer as manufacturer,
    t.model_number as model_number,
    t.manuf_part_number as manuf_part_no,
    t.manuf_serial_number as manuf_serial_number,
    format('{:4d}', date_part('year', t.startup_date)) as construct_year,
    format('{:02d}', date_part('month', t.startup_date)) as construct_mth,
    t1.cat_prof as catalog_profile,
    t.functional_location as functional_loc,
    t.super_equi_id as superord_equip,
    format('{:04d}',t.position) as position,
    t.tech_ident_number as tech_ident_no,
    'ZEQUIPST' as status_profile,
    t.user_status as status_of_an_object,
    t.user_status as status_without_stsno,
from read_parquet(getvariable('simple_equi_parquet')) t
left join asset_facts.catalog_profile t1 on t1.cat_prof = t.equi_class;

    

-- SOLUTION_ID
insert into sqlite_db.equi_create_classification by name
select
    t.batch_number as batch_number,
    t.temp_id as equipment,
    'SOLUTION_ID' as class,
    'SOLUTION_ID' as characteristics,
    t.solution_id as char_value,
from read_parquet(getvariable('simple_equi_parquet')) t
where t.solution_id is not null;

-- LOCATION_ON_SITE
insert into sqlite_db.equi_create_classification by name
select
    t.batch_number as batch_number,
    t.temp_id as equipment,
    t.equi_class as class,
    'LOCATION_ON_SITE' as characteristics,
    t.location_on_site as char_value,
from read_parquet(getvariable('simple_equi_parquet')) t;

-- EASTING
insert into sqlite_db.equi_create_classification by name
select
    t.batch_number as batch_number,
    t.temp_id as equipment,
    'EAST_NORTH' as class,
    'EASTING' as characteristics,
    if(t.easting is not null, 
        format('{:d}', t.easting), 
        format('{:d}', asset_lib.get_east_north(t.grid_ref).easting)) as char_value
from read_parquet(getvariable('simple_equi_parquet')) t
where t.easting is not null or t.grid_ref is not null;


-- NORTHING
insert into sqlite_db.equi_create_classification by name
select
    t.batch_number as batch_number,
    t.temp_id as equipment,
    'EAST_NORTH' as class,
    'NORTHING' as characteristics,
    if(t.northing is not null, 
        format('{:d}', t.northing), 
        format('{:d}', asset_lib.get_east_north(t.grid_ref).northing)) as char_value
from read_parquet(getvariable('simple_equi_parquet')) t
where t.northing is not null or t.grid_ref is not null;


-- AI2_AIB_REFERENCE (pli)
insert into sqlite_db.equi_create_classification by name
select
    t.batch_number as batch_number,
    t.temp_id as equipment,
    'AIB_REFERENCE' as class,
    'AI2_AIB_REFERENCE' as characteristics,
    t.ai2_pli_number as char_value,
from read_parquet(getvariable('simple_equi_parquet')) t
where t.ai2_pli_number is not null;

-- AI2_AIB_REFERENCE (sai)
insert into sqlite_db.equi_create_classification by name
select
    t.batch_number as batch_number,
    t.temp_id as equipment,
    'AIB_REFERENCE' as class,
    'AI2_AIB_REFERENCE' as characteristics,
    t.ai2_sai_number as char_value,
from read_parquet(getvariable('simple_equi_parquet')) t
where t.ai2_sai_number is not null;

-- CONDITION_GRADE
insert into sqlite_db.equi_create_classification by name
select
    t.batch_number as batch_number,
    t.temp_id as equipment,
    'ASSET_CONDITION' as class,
    'CONDITION_GRADE' as characteristics,
    t.condition_grade as char_value,
from read_parquet(getvariable('simple_equi_parquet')) t
where t.condition_grade is not null;

-- CONDITION_GRADE_REASON
insert into sqlite_db.equi_create_classification by name
select
    t.batch_number as batch_number,
    t.temp_id as equipment,
    'ASSET_CONDITION' as class,
    'CONDITION_GRADE_REASON' as characteristics,
    t.condition_grade_reason as char_value,
from read_parquet(getvariable('simple_equi_parquet')) t
where t.condition_grade_reason is not null;

-- SURVEY_YEAR
insert into sqlite_db.equi_create_classification by name
select
    t.batch_number as batch_number,
    t.temp_id as equipment,
    'ASSET_CONDITION' as class,
    'SURVEY_DATE' as characteristics,
    format('{:4d}', t.survey_year) as char_value,
from read_parquet(getvariable('simple_equi_parquet')) t
where t.survey_year is not null;

-- detach `` when done
