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



create schema if not exists simple_equi_landing;
create schema if not exists simple_equi;



create or replace table simple_equi.worklist (
    temp_id varchar not null,
    batch_number integer,
    equi_name varchar not null,
    equi_category varchar,
    functional_location varchar,
    super_equi_id varchar,
    equi_type varchar,
    equi_class varchar,
    weight_kg decimal,
    startup_date varchar,
    manufacturer varchar,
    model_number varchar,
    manuf_part_number varchar,
    manuf_serial_number varchar,
    position integer,
    tech_ident_number varchar,
    user_status varchar,
    ai2_pli_number varchar,
    ai2_sai_number varchar,
    location_on_site varchar,
    grid_ref varchar,
    easting integer,
    northing integer,
    solution_id varchar,
    condition_grade varchar,
    condition_grade_reason varchar,
    survey_year integer,
    primary key (temp_id)
);

create or replace table simple_equi.catalog_profile (
    cat_prof varchar not null,
    description varchar,
    primary key (cat_prof)
);

create or replace MACRO get_east_north_struct(gridref) AS (
with cte_major as (
    select * from
        (values
            ('S', 0,        0),
            ('T', 500_000,  0),
            ('N', 0,        500_000),
            ('O', 500_000,  500_000),
            ('H', 0,        1_000_000),
        ) east_north_major(ix, east, north)
), cte_minor as (
    select * from
        (values
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
), cte1 as (
    select
        upper(gridref[1]) as major_letter,
        upper(gridref[2]) as minor_letter,
        try_cast(gridref[3:7] as integer) as east1,
        try_cast(gridref[8:12] as integer) as north1,
), cte2 as (
    select
        t_major.east + t_minor.east + cte1.east1 as easting,
        t_major.north + t_minor.north + cte1.north1 as northing,
    from cte1
    left join cte_major t_major on t_major.ix = cte1.major_letter
    left join cte_minor t_minor on t_minor.ix = cte1.minor_letter
)
select
    struct_pack(easting := cte2.easting, northing := cte2.northing)
from cte2
);


