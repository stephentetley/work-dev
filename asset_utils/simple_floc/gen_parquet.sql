--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `source_simple_floc_xlsx` and `dest_simple_floc_parquet` are set in 
-- DuckDB (i.e. not env vars)
--



.bail on
load excel;

set variable inputs = ['source_simple_floc_xlsx', 'dest_simple_floc_parquet'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));





create or replace temporary table table1 as
with cte1_raw as (
    select 
        row_number() over () as source_row,
        base_macros.nulled(trim(columns(t.*))),
    from read_xlsx(
        getvariable('source_simple_floc_xlsx'),
        all_varchar=true, 
        sheet='NewFloc'
    ) as t
)
select 
    t.source_row,
    coalesce(try_cast(t."Batch Number" as integer), 1) as batch_number,
    t."Functional Location" as functional_location,
    t."Floc Name" as floc_name,
    try_cast(t."Category" as integer) as floc_category,
    t."Str Indicator" as str_indicator,
    t."Floc Type" as floc_type,
    t."Level5 System Class" as level5_system_class,
    t."Level5 System Name" as level5_system_name,
    try(strptime(t."Startup Date", '%d.%m.%Y')::date) as startup_date,
    try_cast(t."Position" as integer) as position,
    try_cast(t."Maint Plant" as integer) as maint_plant,
    try_cast(t."Cost Center" as integer) as cost_center,
    t."Main Work Center" as main_work_center,
    t."Plant Section" as plant_section,
    upper(t."Installation Allowed") == 'X' as installation_allowed,
    t."User Status" as user_status,
    t."AI2 SAI Number" as ai2_sai_number,
    t."Grid Ref" as grid_ref,
    try_cast(t."Easting" as integer) as easting,
    try_cast(t."Northing" as integer) as northing,
    t."Solution ID" as solution_id,
from cte1_raw t
where t."Functional Location" is not null and t."Floc Name" is not null;


-- Don't fix the output table name, user defined...
copy (
    select * from table1 order by batch_number, functional_location
) to (getvariable('dest_simple_floc_parquet')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_simple_floc_parquet') as result;



