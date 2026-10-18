    --
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--


-- Preliminaries: 
-- `base_macros_catalog` is attached as `base_macros` (read_only)
-- `asset_facts_catalog` is attached as `asset_facts` (read_only)
-- `asset_lib_catalog` is attached as `asset_lib` (read_only)
-- The variable `floc_delta_worklist_xlsx` is set in DuckDb (i.e. not an env var)
-- The variable `existing_flocs_parquet` is set in DuckDb (i.e. not an env var)
-- The variable `dest_simple_floc_xlsx` is set in DuckDb (i.e. not an env var)

.bail on
load excel;

set variable inputs = ['floc_delta_worklist_xlsx', 'existing_flocs_parquet', 'dest_simple_floc_xlsx'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));


with cte1_databases as (
select 
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


--
create or replace temporary table worklist(
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

create or replace temporary table existing_flocs (
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


create or replace temporary table existing_and_new_flocs (
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


create or replace temporary table new_generated_flocs (
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

create or replace temporary view vw_existing_ancestor as 
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

create or replace temporary view vw_new_flocs as 
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


insert into worklist by name
with cte1_raw as (
    select 
        nulled_trim(columns(t.*))
    from read_xlsx(
        getvariable('floc_delta_worklist_xlsx'),
        all_varchar=true, 
        sheet='Flocs'
    ) as t
), cte2_defined_columns as (
    select 
        t."Requested Floc" as requested_floc,
        t."Name" as floc_description,
        t."Object Type" as object_type,
        t."Level 5 Class Type" as class_type,
        t."Asset Status" as user_status,
        t."Level 5 System Type Name" as level5_system_name,
        t."AIB Reference" as aib_reference,
        t."Solution ID" as solution_id,
        asset_lib.get_east_north(t."Grid Ref (Override)") as __grid_ref,
    from read_xlsx(
        getvariable('floc_delta_worklist_xlsx'),
        all_varchar=true, 
        sheet='Flocs'
    ) as t
) 
select 
    t.* exclude(__grid_ref),
    t.__grid_ref['easting'] as easting,
    t.__grid_ref['northing'] as northing,
from cte2_defined_columns t;



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


insert into existing_and_new_flocs by name (
with cte1_worklist_items as (
    select 
        t.requested_floc as floc, 
        t.floc_description as source_name,
        t.object_type as source_type,
        t.class_type as source_class_type,
        regexp_split_to_array(floc, '-') as arr,
        len(arr) as floc_category,
        list_extract(arr, 1) as site,
        list_extract(arr, 2) as func,
        list_extract(arr, 3) as proc_grp,
        list_extract(arr, 4) as proc,
        list_extract(arr, 5) as sysm,
        list_extract(arr, 6) as subsysm,
        if (func        is not null, concat_ws('-', site, func), null) as level2,
        if (proc_grp    is not null, concat_ws('-', site, func, proc_grp), null) as level3,
        if (proc        is not null, concat_ws('-', site, func, proc_grp, proc), null) as level4,
        if (sysm        is not null, concat_ws('-', site, func, proc_grp, proc, sysm), null) as level5,
        if (floc_category = 6,       concat_ws('-', site, func, proc_grp, proc, sysm, subsysm), null) as level6,
        t.user_status as user_status,
        t.easting as easting,
        t.northing as northing,
        t.solution_id as solution_id,
        t.level5_system_name as level5_system_name,
    from worklist t
), cte2_add_234_descriptions as (
    select 
        t1.*,
        t2.standard_floc_description as name_2,
        t3.standard_floc_description as name_3,
        t4.standard_floc_description as name_4,
    from cte1_worklist_items t1
    left join asset_facts.ztables.floc_object_type_description t2 on t2.object_type = t1.func
    left join asset_facts.ztables.floc_object_type_description t3 on t3.object_type = t1.proc_grp
    left join asset_facts.ztables.floc_object_type_description t4 on t4.object_type = t1.proc
)  
(select  
    -- Level 1 (site)
    site as funcloc,
    source_name as floc_name,
    1 as floc_category,
    'SITE' as floc_type,
    null as floc_class,
    null as parent_floc,
    null as user_status,
    null as easting,
    null as northing,
    null as solution_id,
from cte2_add_234_descriptions where cte2_add_234_descriptions.floc_category = 1)
union by name
(select 
    -- Level 2 (function)
    level2 as funcloc,
    name_2 as floc_name,
    2 as floc_category,
    func as floc_type,
    null as floc_class,
    site as parent_floc,
    null as user_status,
    null as easting,
    null as northing,
    null as solution_id,
    null as level5_system_name,
from cte2_add_234_descriptions where cte2_add_234_descriptions.level2 is not null)
union by name 
(select 
    -- Level 3 (process group)
    level3 as funcloc,
    name_3 as floc_name,
    3 as floc_category,
    proc_grp as floc_type,
    null as floc_class,
    level2 as parent_floc,
    null as user_status,
    null as easting,
    null as northing,
    null as solution_id,
    null as level5_system_name,
from cte2_add_234_descriptions where cte2_add_234_descriptions.level3 is not null)
union by name
(select 
    -- Level 4 (process)
    level4 as funcloc,
    name_4 as floc_name,
    4 as floc_category,
    proc as floc_type,
    null as floc_class,
    level3 as parent_floc,
    null as user_status,
    null as easting,
    null as northing,
    null as solution_id,
    null as level5_system_name,
from cte2_add_234_descriptions where cte2_add_234_descriptions.level4 is not null)
union by name
(select 
    -- Level 5 (system)
    level5 as funcloc, 
    source_name as floc_name, 
    5 as floc_category,
    source_class_type as floc_class,
    source_type as floc_type, 
    level4 as parent_floc,
    user_status as user_status,
    easting as easting,
    northing as northing,
    solution_id as solution_id,
    level5_system_name as level5_system_name,
from cte2_add_234_descriptions where cte2_add_234_descriptions.floc_category = 5)
union by name
(select 
    -- Level 6 (subsystem)
    level6 as funcloc, 
    source_name as floc_name,
    6 as floc_category,
    source_type as floc_type, 
    null as floc_class,
    level5 as parent_floc,
    user_status,
    easting,
    northing,
    solution_id,
    null as level5_system_name,
from cte2_add_234_descriptions where cte2_add_234_descriptions.floc_category = 6)
order by funcloc
);


insert into new_generated_flocs by name (
select t1.* 
from existing_and_new_flocs t1
anti join existing_flocs t2 on t2.funcloc = t1.funcloc
order by funcloc
);


create or replace temporary view vw_floc_delta_simple_floc as 
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


-- Don't fix the output table name...
copy (
    select * from vw_floc_delta_simple_floc order by "Functional Location"
) to (getvariable('dest_simple_floc_xlsx')) (format xlsx, header true, sheet 'NewFloc');

select 'Wrote: ' || getvariable('dest_simple_floc_xlsx') as result;

