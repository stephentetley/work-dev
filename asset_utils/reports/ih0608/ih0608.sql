--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `floc_minimal_source_parquet`, `equi_minimal_source_parquet' and `dest_report_xlsx` 
-- are set in DuckDB (i.e. not env vars)
--

.bail on
load excel;


set variable inputs = ['floc_minimal_source_parquet', 'equi_minimal_source_parquet', 'dest_report_xlsx'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));



create or replace temporary view vw_source_floc as
select * from read_parquet(getvariable('floc_minimal_source_parquet'));

create or replace temporary view vw_source_equi as
select * from read_parquet(getvariable('equi_minimal_source_parquet'));

create or replace temporary macro pp_position (pos integer) as
format('{:04d}', coalesce(pos, 9990));

create or replace temporary macro indent_text (level integer, txt varchar) as
repeat('..', level-1) || txt;

create or replace temporary view vw_sort_keys as
with recursive sort_keys(equi_id, sort_key) as (
    select
        t.equi_id,
        t.functional_location || '-' || pp_position(t.position) || '-' || t.equi_id as sort_key,
    from vw_source_equi t
    where t.parent_equi is null
    union
    select
        t.equi_id,
        t1.sort_key || '-' || pp_position(t.position) || '-' || t.equi_id as sort_key,
    from vw_source_equi t
    join sort_keys t1 on t1.equi_id = t.parent_equi
)
select * from sort_keys;

create or replace temporary view vw_indented_floc as
select
    t.functional_location,
    indent_text(t.floc_category, t.floc_name) as indented,
    t.floc_category as level,
from vw_source_floc t;

create or replace temporary view vw_indented_equi as
with recursive working_table(equi_id, indented, level) as (
    select
        t.equi_id,
        indent_text(t1.level + 1, t.equi_name) as indented,
        t1.level + 1 as level,
    from vw_source_equi t
    join vw_indented_floc t1 on t1.functional_location = t.functional_location
    where t.parent_equi is null
    union
    select
        t.equi_id as equi_id,
        indent_text(t1.level + 1, t.equi_name) as indented,
        t1.level + 1 as level,
    from vw_source_equi t
    join working_table t1 on t1.equi_id = t.parent_equi
)
select * from working_table;


create or replace temporary view vw_floc as
select
    'Floc' as "Row Type",
    t.functional_location as "Sort Key",
    t.functional_location as "Floc",
    t.floc_name as "Description",
    t1.indented as "Indented",
    null as "Equi ID",
    null as "Super Equi ID",
    try_cast(t.floc_category as varchar) as "Category",
    t.floc_type as "Type",
    null as "Equi Standard Class",
    strftime(t.startup_date, '%d.%m.%Y') as "Start-up Date",
    t.user_status as "User Status",
    null as "Manufacturer",
    null as "Model",
    null as "Part Number",
    null as "Serial Number",
    null as "Tech Ident No",
    format('{:04d}', t.position) as "Position",
    t.maint_plant as "Maint Plant",
    t.cost_center as "Cost Center",
    t.main_work_center as "Main Work Center",
    t.easting as "Easting",
    t.northing as "Northing",
    array_to_string(t.aib_numbers, ', ') as "AIB Numbers",
from vw_source_floc t
left join vw_indented_floc t1 on t1.functional_location = t.functional_location;


create or replace temporary view vw_equi as
select
    'Equi' as "Row Type",
    t1.sort_key as "Sort Key",
    t.functional_location as "Floc",
    t.equi_name as "Description",
    t2.indented as "Indented",
    t.equi_id as "Equi ID",
    t.parent_equi as "Super Equi ID",
    t.equi_category as "Category",
    t.equi_type as "Type",
    t.standard_class as "Equi Standard Class",
    strftime(t.startup_date, '%d.%m.%Y') as "Start-up Date",
    t.user_status as "User Status",
    t.manufacturer as "Manufacturer",
    t.model as "Model",
    t.part_number as "Part Number",
    t.serial_number as "Serial Number",
    t.tech_ident_num as "Tech Ident No",
    format('{:04d}', t.position) as "Position",
    t.maint_plant as "Maint Plant",
    t.cost_center as "Cost Center",
    t.main_work_center as "Main Work Center",
    t.easting as "Easting",
    t.northing as "Northing",
    array_to_string(t.aib_numbers, ', ') as "AIB Numbers",
from vw_source_equi t
join vw_sort_keys t1 on t1.equi_id = t.equi_id
left join vw_indented_equi t2 on t2.equi_id = t.equi_id;

create or replace temporary view vw_site_report as
select * from vw_floc
union by name
select * from vw_equi
order by "Sort Key";

copy (
    select * from vw_site_report order by "Sort Key"
) to (getvariable('dest_report_xlsx')) (format xlsx, header true);

select 'Wrote: ' || getvariable('dest_report_xlsx') as result;

