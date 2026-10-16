    --
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--


-- Preliminaries: 
-- `asset_facts_catalog` is attached as `asset_facts` (read_only)
-- `asset_lib_catalog` is attached as `asset_lib` (read_only)
-- The variable `worklist_xlsx` is set in DuckDb (i.e. not an env var)
-- The variable `existing_flocs_parquet` is set in DuckDb (i.e. not an env var)
-- The variable `dest_xlsx` is set in DuckDb (i.e. not an env var)



--
create or replace table worklist(
    requested_floc varchar not null,
    floc_description varchar,
    object_type varchar,
    class_type varchar,
    user_status varchar,
    level5_system_name varchar,
    easting integer,
    northing integer,
    solution_id varchar,
    aib_reference varchar,
    primary key (requested_floc)
);

create or replace table existing_flocs (
    funcloc varchar not null,
    floc_name varchar,
    floc_category integer,
    user_status varchar,
    startup_date date,
    cost_center integer,
    main_work_center varchar,
    maintenance_plant varchar,
    plant_section varchar,
    easting integer,
    northing integer,
    primary key (funcloc)
);


create or replace table existing_and_new_flocs (
    funcloc varchar,
    floc_name varchar,
    floc_category integer,
    user_status varchar,
    floc_type varchar,
    floc_class varchar,
    parent_floc varchar,
    easting integer,
    northing integer,
    solution_id varchar,
    level5_system_name varchar,
    primary key (funcloc)
    );


create or replace table new_generated_flocs (
    funcloc varchar not null,
    floc_name varchar,
    floc_category integer,
    user_status varchar,
    floc_type varchar,
    floc_class varchar,
    parent_floc varchar,
    easting integer,
    northing integer,
    solution_id varchar,
    level5_system_name varchar,
    primary key (funcloc)
    );

create or replace view vw_existing_ancestor as 
with cte1_join_new_and_old as (
    select 
        t.funcloc as gen_funcloc, 
        t1.funcloc as ancestor,
    from new_generated_flocs t
    join existing_flocs t1 on starts_with(t.funcloc, t1.funcloc )
) 
select gen_funcloc as new_funcloc, max(ancestor) as existing_ancestor
from cte1_join_new_and_old
group by gen_funcloc;

create or replace view vw_new_flocs as 
select 
    t.* exclude(easting, northing, user_status),
    t1.existing_ancestor,
    t2.startup_date,
    t2.cost_center,
    t2.main_work_center,
    t2.maintenance_plant,
    if (t.floc_category = 4, t.floc_type, null) as plant_section,
    coalesce(t.user_status, t2.user_status) as user_status,
    coalesce(t.easting, t2.easting) as easting,
    coalesce(t.northing, t2.northing) as northing,
    t3.aib_reference as aib_reference
from new_generated_flocs t
left outer join vw_existing_ancestor t1 on t1.new_funcloc = t.funcloc
left outer join existing_flocs t2 on t2.funcloc = t1.existing_ancestor
left outer join worklist t3 on t3.requested_floc = t.funcloc;

-- Set the variable `worklist_xlsx` before running this file
select getvariable('worklist_xlsx') as worklist_xlsx;

insert into worklist by name
with cte1_source as (
    select 
        t."Requested Floc" AS requested_floc,
        t."Name" AS floc_description,
        t."Object Type" AS object_type,
        t."Level 5 Class Type" AS class_type,
        t."Asset Status" AS user_status,
        t."Level 5 System Type Name" AS level5_system_name,
        t."AIB Reference" AS aib_reference,
        t."Solution ID" AS solution_id,
        asset_lib.get_east_north(t."Grid Ref (Override)") AS __grid_ref,
    from read_xlsx(
        getvariable('worklist_xlsx'),
        all_varchar=true, 
        sheet='Flocs'
    ) AS t
) 
select 
    t.* exclude(__grid_ref),
    t.__grid_ref['easting'] AS easting,
    t.__grid_ref['northing'] AS northing,
from cte1_source t;


-- Set the variable `existing_flocs_parquet` before running this file
select getvariable('existing_flocs_parquet') as existing_flocs_parquet;

insert into existing_flocs by name
with cte1_source as (
    select 
        * 
    from read_parquet(getvariable('existing_flocs_parquet'))
)
select 
    t.functional_location as funcloc,
    t.floc_name,
    t.floc_category,
    t.user_status,
    t.startup_date,
    t.cost_center,
    t.main_work_center,
    t.maint_plant as maintenance_plant,
    t.plant_section,
    t.easting,
    t.northing,
from cte1_source t;


-- 
-- This is the main processing
-- 


INSERT INTO existing_and_new_flocs BY NAME (
WITH cte1 AS (
    SELECT 
        t.requested_floc AS floc, 
        t.floc_description AS source_name,
        t.object_type AS source_type,
        t.class_type AS source_class_type,
        regexp_split_to_array(floc, '-') AS arr,
        len(arr) as floc_category,
        list_extract(arr, 1) as site,
        list_extract(arr, 2) AS func,
        list_extract(arr, 3) AS proc_grp,
        list_extract(arr, 4) AS proc,
        list_extract(arr, 5) AS sysm,
        list_extract(arr, 6) AS subsysm,
        IF (func        IS NOT NULL, concat_ws('-', site, func), NULL) AS level2,
        IF (proc_grp    IS NOT NULL, concat_ws('-', site, func, proc_grp), NULL) AS level3,
        IF (proc        IS NOT NULL, concat_ws('-', site, func, proc_grp, proc), NULL) AS level4,
        IF (sysm        IS NOT NULL, concat_ws('-', site, func, proc_grp, proc, sysm), NULL) AS level5,
        IF (floc_category = 6,       concat_ws('-', site, func, proc_grp, proc, sysm, subsysm), NULL) AS level6,
        t.user_status AS user_status,
        t.easting AS easting,
        t.northing AS northing,
        t.solution_id AS solution_id,
        t.level5_system_name AS level5_system_name,
    FROM worklist t
), cte2 AS (
    SELECT 
        t1.*,
        t2.standard_floc_description AS name_2,
        t3.standard_floc_description AS name_3,
        t4.standard_floc_description AS name_4,
    FROM cte1 t1
    LEFT JOIN asset_facts.ztables.floc_object_type_description t2 ON t2.object_type = t1.func
    LEFT JOIN asset_facts.ztables.floc_object_type_description t3 ON t3.object_type = t1.proc_grp
    LEFT JOIN asset_facts.ztables.floc_object_type_description t4 ON t4.object_type = t1.proc
)  
(SELECT  
    -- Level 1 (site)
    site AS funcloc,
    source_name AS floc_name,
    1 AS floc_category,
    'SITE' AS floc_type,
    NULL AS floc_class,
    NULL AS parent_floc,
    NULL AS user_status,
    NULL AS easting,
    NULL AS northing,
    NULL AS solution_id,
FROM cte2 WHERE cte2.floc_category = 1)
UNION BY NAME
(SELECT 
    -- Level 2 (function)
    level2 AS funcloc,
    name_2 AS floc_name,
    2 AS floc_category,
    func AS floc_type,
    NULL AS floc_class,
    site AS parent_floc,
    NULL AS user_status,
    NULL AS easting,
    NULL AS northing,
    NULL AS solution_id,
    NULL AS level5_system_name,
FROM cte2 WHERE cte2.level2 IS NOT NULL)
UNION BY NAME 
(SELECT 
    -- Level 3 (process group)
    level3 AS funcloc,
    name_3 AS floc_name,
    3 AS floc_category,
    proc_grp AS floc_type,
    NULL AS floc_class,
    level2 AS parent_floc,
    NULL AS user_status,
    NULL AS easting,
    NULL AS northing,
    NULL AS solution_id,
    NULL AS level5_system_name,
FROM cte2 WHERE cte2.level3 IS NOT NULL)
UNION BY NAME
(SELECT 
    -- Level 4 (process)
    level4 AS funcloc,
    name_4 AS floc_name,
    4 AS floc_category,
    proc AS floc_type,
    NULL AS floc_class,
    level3 AS parent_floc,
    NULL AS user_status,
    NULL AS easting,
    NULL AS northing,
    NULL AS solution_id,
    NULL AS level5_system_name,
FROM cte2 WHERE cte2.level4 IS NOT NULL)
UNION BY NAME
(SELECT 
    -- Level 5 (system)
    level5 AS funcloc, 
    source_name AS floc_name, 
    5 AS floc_category,
    source_class_type AS floc_class,
    source_type AS floc_type, 
    level4 AS parent_floc,
    user_status AS user_status,
    easting AS easting,
    northing AS northing,
    solution_id as solution_id,
    level5_system_name AS level5_system_name,
FROM cte2 WHERE cte2.floc_category = 5)
UNION BY NAME
(SELECT 
    -- Level 6 (subsystem)
    level6 AS funcloc, 
    source_name AS floc_name,
    6 AS floc_category,
    source_type AS floc_type, 
    NULL AS floc_class,
    level5 AS parent_floc,
    user_status,
    easting,
    northing,
    solution_id,
    NULL AS level5_system_name,
FROM cte2 WHERE cte2.floc_category = 6)
ORDER BY funcloc
);




INSERT INTO new_generated_flocs BY NAME (
SELECT t1.* 
FROM existing_and_new_flocs t1
ANTI JOIN existing_flocs t2 ON t2.funcloc = t1.funcloc
ORDER BY funcloc
);


create table floc_delta_simple_floc as 
select 
    1 as "Batch Number",
    t.funcloc as "Functional Location",
    t.floc_name  as "Floc Name",
    t.floc_category as "Category",
    'YW-GS' as "Str Indicator",
    t.floc_type as "Floc Type",
    t.floc_class as "Level5 System Class",
    t.level5_system_name as "Level5 System Name",
    strftime(t.startup_date, '%d.%m.%Y') as "Startup Date",
    t.maintenance_plant as "Maint Plant",
    t.cost_center as "Cost Center",
    t.main_work_center as "Main Work Center",
    t.plant_section as "Plant Section",
    if(t.floc_category >= 5, 'X', null) "Installation Allowed",
    t.user_status as "User Status",
    t.aib_reference as "AI2 SAI Number",
    null as "Grid Ref",
    t.easting as "Easting",
    t.northing as "Northing",
    t.solution_id as "Solution ID",
    null as "Position",
from vw_new_flocs t
order by t.funcloc;

select * from floc_delta_simple_floc;



-- Set the variable `dest_xlsx` before running this file
select getvariable('dest_xlsx') as dest_xlsx;


-- Don't fix the output table name...
copy (
    select * from floc_delta_simple_floc order by "Functional Location"
) to (getvariable('dest_xlsx')) (format xlsx, header true, sheet 'NewFloc');

select 'Wrote: ' || getvariable('dest_xlsx') as result;