-- 
-- Copyright 2025 Stephen Tetley
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



INSERT INTO sqlite_db.floc_create_functional_location BY NAME
SELECT
    1 as batch_number,
    t.funcloc AS functional_location,
    t.floc_name AS floc_description,
    t.floc_category AS category,
    'YW-GS' AS str_indicator,
    t.floc_type AS object_type,
    strftime(t.startup_date, '%d.%m.%Y') AS start_up_date,
    strftime(t.startup_date, '%Y') AS construct_year,
    strftime(t.startup_date, '%m') AS construct_mth,    
    t.maintenance_plant AS maint_plant,
    t.plant_section AS plant_section,
    IF(t.floc_category IN ('5', '6'), 'X', null) AS installation_allowed,
    'ZFLOCST' AS status_profile,
    t.user_status AS user_status,
    t.user_status AS status_of_an_object,
FROM floc_delta.vw_new_flocs t;

    

-- SOLUTION_ID
INSERT INTO sqlite_db.floc_create_classification BY NAME
SELECT
    1 as batch_number,
    t.funcloc AS functional_location,
    'SOLUTION_ID' AS class,
    'SOLUTION_ID' AS characteristics,
    t.solution_id AS char_value,
FROM floc_delta.vw_new_flocs t
WHERE t.solution_id IS NOT NULL;

-- EASTING
INSERT INTO sqlite_db.floc_create_classification BY NAME
SELECT
    1 as batch_number,
    t.funcloc AS functional_location,
    'EAST_NORTH' AS class,
    'EASTING' AS characteristics,
    printf('%d', t.easting) AS char_value,
FROM floc_delta.vw_new_flocs t
WHERE t.easting IS NOT NULL;


-- NORTHING
INSERT INTO sqlite_db.floc_create_classification BY NAME
SELECT
    1 as batch_number,
    t.funcloc AS functional_location,
    'EAST_NORTH' AS class,
    'NORTHING' AS characteristics,
    printf('%d', t.northing) AS char_value,
FROM floc_delta.vw_new_flocs t
WHERE t.northing IS NOT NULL;

-- Level 5 systems with SYSTEM_TYPE
INSERT INTO sqlite_db.floc_create_classification BY NAME
SELECT
    1 as batch_number,
    t.funcloc AS functional_location,
    t.floc_class AS class,
    'SYSTEM_TYPE' AS characteristics,
    t.level5_system_name AS char_value,
FROM floc_delta.vw_new_flocs t
WHERE t.level5_system_name IS NOT NULL;


-- AI2_AIB_REFERENCE
INSERT INTO sqlite_db.floc_create_classification BY NAME
SELECT
    1 as batch_number,
    t.funcloc AS functional_location,
    'AIB_REFERENCE' AS class,
    'AI2_AIB_REFERENCE' AS characteristics,
    t.aib_reference AS char_value,
FROM floc_delta.vw_new_flocs t;



