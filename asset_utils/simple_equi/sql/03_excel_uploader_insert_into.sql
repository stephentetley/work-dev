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



insert into sqlite_db.equi_create_equipment_data by name
select
    1 as batch_number,
    t.temp_id as equipment,
    t.equi_category as equip_category,
    t.equi_name as description_medium,
    t.equi_type as object_type,
    if(t.weight_kg is not null, format('{:.2f}', t.weight_kg), null) as gross_weight,
    if(t.weight_kg is not null, 'KG', null)as unit_of_weight,
    t.startup_date as start_up_date,
    t.manufacturer as manufacturer,
    t.model_number as model_number,
    t.manuf_part_number as manuf_part_no,
    t.manuf_serial_number as manuf_serial_number,
    format('{:4d}', date_part('year', strptime(t.startup_date, '%d.%m.%Y'))) as construct_year,
    format('{:02d}', date_part('month', strptime(t.startup_date, '%d.%m.%Y'))) as construct_mth,
    t.functional_location as functional_loc,
    t.super_equi_id as superord_equip,
    format('{:04d}',t.position) as position,
    t.tech_ident_number as tech_ident_no,
    'ZEQUIPST' as status_profile,
    t.user_status as status_of_an_object,
    t.user_status as status_without_stsno,
from simple_equi.worklist t;

    

-- SOLUTION_ID
insert into sqlite_db.equi_create_classification by name
select
    1 as batch_number,
    t.temp_id as equipment,
    'SOLUTION_ID' as class,
    'SOLUTION_ID' as characteristics,
    t.solution_id as char_value,
from simple_equi.worklist t
where t.solution_id is not null;

-- LOCATION_ON_SITE
insert into sqlite_db.equi_create_classification by name
select
    1 as batch_number,
    t.temp_id as equipment,
    t.equi_class as class,
    'LOCATION_ON_SITE' as characteristics,
    t.location_on_site as char_value,
from simple_equi.worklist t;

-- EASTING
insert into sqlite_db.equi_create_classification by name
select
    1 as batch_number,
    t.temp_id as equipment,
    'EAST_NORTH' as class,
    'EASTING' as characteristics,
    if(t.easting is not null, 
        format('{:d}', t.easting), 
        format('{:d}', get_east_north_struct(t.grid_ref).easting)) as char_value
from simple_equi.worklist t
where t.easting is not null or t.grid_ref is not null;


-- EASTING
insert into sqlite_db.equi_create_classification by name
select
    1 as batch_number,
    t.temp_id as equipment,
    'EAST_NORTH' as class,
    'NORTHING' as characteristics,
    if(t.northing is not null, 
        format('{:d}', t.easting), 
        format('{:d}', get_east_north_struct(t.grid_ref).northing)) as char_value
from simple_equi.worklist t
where t.northing is not null or t.grid_ref is not null;


-- AI2_AIB_REFERENCE (pli)
insert into sqlite_db.equi_create_classification by name
select
    1 as batch_number,
    t.temp_id as equipment,
    'AIB_REFERENCE' as class,
    'AI2_AIB_REFERENCE' as characteristics,
    t.ai2_pli_number as char_value,
from simple_equi.worklist t
where t.ai2_pli_number is not null;

-- AI2_AIB_REFERENCE (sai)
insert into sqlite_db.equi_create_classification by name
select
    1 as batch_number,
    t.temp_id as equipment,
    'AIB_REFERENCE' as class,
    'AI2_AIB_REFERENCE' as characteristics,
    t.ai2_sai_number as char_value,
from simple_equi.worklist t
where t.ai2_sai_number is not null;

-- CONDITION_GRADE
insert into sqlite_db.equi_create_classification by name
select
    1 as batch_number,
    t.temp_id as equipment,
    'ASSET_CONDITION' as class,
    'CONDITION_GRADE' as characteristics,
    t.condition_grade as char_value,
from simple_equi.worklist t
where t.condition_grade is not null;

-- CONDITION_GRADE_REASON
insert into sqlite_db.equi_create_classification by name
select
    1 as batch_number,
    t.temp_id as equipment,
    'ASSET_CONDITION' as class,
    'CONDITION_GRADE_REASON' as characteristics,
    t.condition_grade_reason as char_value,
from simple_equi.worklist t
where t.condition_grade_reason is not null;

-- SURVEY_YEAR
insert into sqlite_db.equi_create_classification by name
select
    1 as batch_number,
    t.temp_id as equipment,
    'ASSET_CONDITION' as class,
    'SURVEY_YEAR' as characteristics,
    format('{:4d}', t.survey_year) as char_value,
from simple_equi.worklist t
where t.survey_year is not null;
