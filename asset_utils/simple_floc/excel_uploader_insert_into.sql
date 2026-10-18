--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--



-- Preliminaries: 
-- Must have a sqlite database attached called `sqlite_db` (read-write)
-- and `asset_facts` and `asset_lib` DuckDB catalogs attached as read only
-- The variable `simple_floc_parquet` is set in DuckDB (i.e. not an env var)
--
-- Run from DuckDB - no need for standalone SQLite to be installed 
-- 

.bail on

set variable inputs = ['simple_floc_parquet'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));

from base_macros.assert_databases_are_loaded(['base_macros', 'asset_facts'. 'asset_lib', 'sqlite_db']);



insert into sqlite_db.floc_create_functional_location by name
select
    t.batch_number as batch_number,
    t.functional_location as functional_location,
    t.floc_name as floc_description,
    t.floc_category as category,
    t.str_indicator as str_indicator,
    t.floc_type as object_type,
    strftime(t.startup_date, '%d.%m.%Y') as start_up_date,
    format('{:4d}', date_part('year', t.startup_date)) as construct_year,
    format('{:02d}', date_part('month', t.startup_date)) as construct_mth,
    t.maint_plant as maint_plant,
    t.cost_center as cost_center,
    t.main_work_center as main_work_ctr,
    plant_section as plant_section,
    format('{:04d}',t.position) as position,
    t.installation_allowed as installation_allowed,
    'ZFLOCST' as status_profile,
    t.user_status as user_status,
    t.user_status as status_of_an_object,
from read_parquet(getvariable('simple_floc_parquet')) t;

    

-- SOLUTION_ID
insert into sqlite_db.floc_create_classification by name
select
    t.batch_number as batch_number,
    t.functional_location as functional_location,
    'SOLUTION_ID' as class,
    'SOLUTION_ID' as characteristics,
    t.solution_id as char_value,
from read_parquet(getvariable('simple_floc_parquet')) t
where t.solution_id is not null;


-- EASTING
insert into sqlite_db.floc_create_classification by name
select
    t.batch_number as batch_number,
    t.functional_location as functional_location,
    'EAST_NORTH' as class,
    'EASTING' as characteristics,
    if(t.easting is not null, 
        format('{:d}', t.easting), 
        format('{:d}', asset_lib.get_east_north(t.grid_ref).easting)) as char_value
from read_parquet(getvariable('simple_floc_parquet')) t
where t.easting is not null or t.grid_ref is not null;


-- NORTHING
insert into sqlite_db.floc_create_classification by name
select
    t.batch_number as batch_number,
    t.functional_location as functional_location,
    'EAST_NORTH' as class,
    'NORTHING' as characteristics,
    if(t.northing is not null, 
        format('{:d}', t.northing), 
        format('{:d}', asset_lib.get_east_north(t.grid_ref).northing)) as char_value
from read_parquet(getvariable('simple_floc_parquet')) t
where t.northing is not null or t.grid_ref is not null;


-- AI2_AIB_REFERENCE (sai)
-- Generate a blank if null
insert into sqlite_db.floc_create_classification by name
select
    t.batch_number as batch_number,
    t.functional_location as functional_location,
    'AIB_REFERENCE' as class,
    'AI2_AIB_REFERENCE' as characteristics,
    t.ai2_sai_number as char_value,
from read_parquet(getvariable('simple_floc_parquet')) t;

-- SYSTEM_TYPE
insert into sqlite_db.floc_create_classification by name
select
    t.batch_number as batch_number,
    t.functional_location as functional_location,
    t.level5_system_class as class,
    'SYSTEM_TYPE' as characteristics,
    t.level5_system_name as char_value,
from read_parquet(getvariable('simple_floc_parquet')) t
where t.level5_system_class is not null;
