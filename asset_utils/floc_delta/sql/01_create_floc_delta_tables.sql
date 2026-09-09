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



CREATE SCHEMA IF NOT EXISTS floc_delta;
CREATE SCHEMA IF NOT EXISTS floc_delta_config;
CREATE SCHEMA IF NOT EXISTS floc_delta_landing;

CREATE OR REPLACE TABLE floc_delta_config.ztable_flocdes (
    object_type VARCHAR NOT NULL,
    standard_floc_description VARCHAR,
);

--        
CREATE OR REPLACE TABLE floc_delta.worklist(
    requested_floc VARCHAR NOT NULL,
    floc_description VARCHAR,
    object_type VARCHAR,
    class_type VARCHAR,
    user_status VARCHAR,
    level5_system_name VARCHAR,
    easting INTEGER,
    northing INTEGER,
    solution_id VARCHAR,
    aib_reference VARCHAR,
    PRIMARY KEY (requested_floc)
);

CREATE OR REPLACE TABLE floc_delta.existing_flocs (
    funcloc VARCHAR NOT NULL,
    floc_name VARCHAR,
    floc_category INTEGER,
    user_status VARCHAR,
    startup_date DATE,
    cost_center INTEGER,
    maint_work_center VARCHAR,
    maintenance_plant VARCHAR,
    plant_section VARCHAR,
    easting INTEGER,
    northing INTEGER,
    PRIMARY KEY (funcloc)
);
    

CREATE OR REPLACE TABLE floc_delta.existing_and_new_flocs (
    funcloc VARCHAR,
    floc_name VARCHAR,
    floc_category INTEGER,
    user_status VARCHAR,
    floc_type VARCHAR,
    floc_class VARCHAR,
    parent_floc VARCHAR,
    easting INTEGER,
    northing INTEGER,
    solution_id VARCHAR,
    level5_system_name VARCHAR,
    PRIMARY KEY (funcloc)
    );


CREATE OR REPLACE TABLE floc_delta.new_generated_flocs (
    funcloc VARCHAR NOT NULL,
    floc_name VARCHAR,
    floc_category INTEGER,
    user_status VARCHAR,
    floc_type VARCHAR,
    floc_class VARCHAR,
    parent_floc VARCHAR,
    easting INTEGER,
    northing INTEGER,
    solution_id VARCHAR,
    level5_system_name VARCHAR,
    PRIMARY KEY (funcloc)
    );

CREATE OR REPLACE VIEW floc_delta.vw_existing_ancestor AS 
WITH cte AS (
SELECT 
    t.funcloc AS gen_funcloc, 
    t1.funcloc AS ancestor,
FROM floc_delta.new_generated_flocs t
JOIN floc_delta.existing_flocs t1 ON  t.funcloc ^@ t1.funcloc 
) 
SELECT gen_funcloc AS new_funcloc, max(ancestor) AS existing_ancestor
FROM cte
GROUP BY gen_funcloc;

CREATE OR REPLACE VIEW floc_delta.vw_new_flocs AS 
SELECT 
    t.* EXCLUDE(easting, northing, user_status),
    t1.existing_ancestor AS existing_ancestor,
    t2.startup_date AS startup_date,
    t2.cost_center AS cost_center,
    t2.maintenance_plant AS maintenance_plant,
    IF (t.floc_category = 4, t.floc_type, NULL) AS plant_section,
    coalesce(t.user_status, t2.user_status) AS user_status,
    coalesce(t.easting, t2.easting) AS easting,
    coalesce(t.northing, t2.northing) AS northing,
    t3.aib_reference AS aib_reference
FROM floc_delta.new_generated_flocs t
LEFT OUTER JOIN floc_delta.vw_existing_ancestor t1 ON t1.new_funcloc = t.funcloc
LEFT OUTER JOIN floc_delta.existing_flocs t2 ON t2.funcloc = t1.existing_ancestor
LEFT OUTER JOIN floc_delta.worklist t3 ON t3.requested_floc = t.funcloc;


CREATE OR REPLACE MACRO get_east_north_struct(gridref) AS (
WITH cte_major AS (
    SELECT * FROM
        (VALUES
            ('S', 0,        0),
            ('T', 500_000,  0),
            ('N', 0,        500_000),
            ('O', 500_000,  500_000),
            ('H', 0,        1_000_000),
        ) east_north_major(ix, east, north)
), cte_minor AS (
    SELECT * FROM
        (VALUES
            ('A', 0,         400_000),
            ('B', 100_000,   400_000),
            ('C', 200_000,   400_000),
            ('D', 300_000,   400_000),
            ('E', 400_000,   400_000),
            ('F', 0,         300_000),
            ('G', 100_000,   300_000),
            ('H', 200_000,   300_000),
            ('J', 300_000,   300_000),
            ('K', 400_000,   300_000),
            ('L', 0,         200_000),
            ('M', 100_000,   200_000),
            ('N', 200_000,   200_000),
            ('O', 300_000,   200_000),
            ('P', 400_000,   200_000),
            ('Q', 0,         100_000),
            ('R', 100_000,   100_000),
            ('S', 200_000,   100_000),
            ('T', 300_000,   100_000),
            ('U', 400_000,   100_000),
            ('V', 0,         0),
            ('W', 100_000,   0),
            ('X', 200_000,   0),
            ('Y', 300_000,   0),
            ('Z', 400_000,   0),
        ) east_north_minor(ix, east, north)
), cte1 AS (
    SELECT
        upper(gridref[1]) AS major_letter,
        upper(gridref[2]) AS minor_letter,
        try_cast(gridref[3:7] AS INTEGER) AS east1,
        try_cast(gridref[8:12] AS INTEGER) AS north1,
), cte2 AS (
    SELECT
        t_major.east + t_minor.east + cte1.east1 AS easting,
        t_major.north + t_minor.north + cte1.north1 AS northing,
    FROM cte1
    LEFT JOIN cte_major t_major ON t_major.ix = cte1.major_letter
    LEFT JOIN cte_minor t_minor ON t_minor.ix = cte1.minor_letter
)
SELECT
    struct_pack(easting := cte2.easting, northing := cte2.northing)
FROM cte2
);


