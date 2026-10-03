--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--


-- Preliminary: 
-- The variable `floc_srcfile` is set in DuckDb (i.e. not an env var)
--


load excel;

insert into simple_floc_worklists
with cte1_raw as (
    select
        row_number() over () as source_row,
        t.*,
    from read_xlsx(getvariable('floc_srcfile'), all_varchar = true, header = true) t
), cte2_typed as (
    select 
        t.source_row,
        getvariable('floc_srcfile') as source_file,
        try_cast(t."Batch Number" as integer) as batch_number,
        t."Functional Location" as functional_location,
        t."Floc Name" as floc_name,
        t."Category" as floc_category,
        t."Str Indicator" as str_indicator,
        t."Floc Type" as floc_type,
        t."Level5 System Class" as level5_system_class,
        t."Level5 System Name" as level5_system_name,
        t."Startup Date" as startup_date,
        try_cast(t."Position" as integer) as position,
        try_cast(t."Maint Plant" as integer) as maint_plant,
        try_cast(t."Cost Center" as integer) as cost_center,
        t."Main Work Center" as main_work_center,
        t."Plant Section" as plant_section,
        t."Installation Allowed" as installation_allowed,
        t."User Status" as user_status,
        t."AI2 SAI Number" as ai2_sai_number,
        t."Grid Ref" as grid_ref,
        try_cast(t."Easting" as integer) as easting,
        try_cast(t."Northing" as integer) as northing,
        t."Solution ID" as solution_id,
    from cte1_raw t
) 
select * from cte2_typed
order by source_row;

