-- 
-- Copyright 2026 Stephen Tetley
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
-- http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 


-- Preliminary: 
-- Must have a sqlite database attached called `sqlite_db`
-- Run from DuckDB - no guarantee SQLite is installed 



insert into sqlite_db.floc_create_functional_location by name
select
    1 as batch_number,
    t.functional_location as functional_location,
    t.floc_name as floc_description,
    t.floc_category as category,
    t.str_indicator as str_indicator,
    t.floc_type as object_type,
    t.startup_date as start_up_date,
    format('{:4d}', date_part('year', strptime(t.startup_date, '%d.%m.%Y'))) as construct_year,
    format('{:02d}', date_part('month', strptime(t.startup_date, '%d.%m.%Y'))) as construct_mth,
    t.maint_plant as maint_plant,
    t.cost_center as cost_center,
    t.main_work_center as main_work_ctr,
    plant_section as plant_section,
    format('{:04d}',t.position) as position,
    t.installation_allowed as installation_allowed,
    'ZFLOCST' as status_profile,
    t.user_status as user_status,
    t.user_status as status_of_an_object,
from simple_floc.worklist t;

    

-- SOLUTION_ID
insert into sqlite_db.floc_create_classification by name
select
    1 as batch_number,
    t.functional_location as functional_location,
    'SOLUTION_ID' as class,
    'SOLUTION_ID' as characteristics,
    t.solution_id as char_value,
from simple_floc.worklist t
where t.solution_id is not null;


-- EASTING
insert into sqlite_db.floc_create_classification by name
select
    1 as batch_number,
    t.functional_location as functional_location,
    'EAST_NORTH' as class,
    'EASTING' as characteristics,
    if(t.easting is not null, 
        format('{:d}', t.easting), 
        format('{:d}', get_east_north_struct(t.grid_ref).easting)) as char_value
from simple_floc.worklist t
where t.easting is not null or t.grid_ref is not null;


-- NORTHING
insert into sqlite_db.floc_create_classification by name
select
    1 as batch_number,
    t.functional_location as functional_location,
    'EAST_NORTH' as class,
    'NORTHING' as characteristics,
    if(t.northing is not null, 
        format('{:d}', t.easting), 
        format('{:d}', get_east_north_struct(t.grid_ref).northing)) as char_value
from simple_floc.worklist t
where t.northing is not null or t.grid_ref is not null;


-- AI2_AIB_REFERENCE (sai)
insert into sqlite_db.floc_create_classification by name
select
    1 as batch_number,
    t.functional_location as functional_location,
    'AIB_REFERENCE' as class,
    'AI2_AIB_REFERENCE' as characteristics,
    t.ai2_sai_number as char_value,
from simple_floc.worklist t
where t.ai2_sai_number is not null;

-- SYSTEM_TYPE
insert into sqlite_db.floc_create_classification by name
select
    1 as batch_number,
    t.functional_location as functional_location,
    t.level5_system_class as class,
    'SYSTEM_TYPE' as characteristics,
    t.level5_system_name as char_value,
from simple_floc.worklist t
where t.level5_system_class is not null;
