--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

load excel;


-- Preliminary: 
-- The variable `equi_srcfile` is set in DuckDb (i.e. not an env var)
--

delete from simple_equi_worklist;
-- Offset source_row by 1 to match Excel
insert into simple_equi_worklist by name
with cte1_raw as (
    select
        1 + row_number() over () as source_row,
        t.*,
    from read_xlsx(getvariable('equi_srcfile'), all_varchar = true, header = true) t
), cte2_typed as (
    select 
        t.source_row,
        try_cast(t."Batch Number" as integer) as batch_number,
        t."Temp ID" as temp_id,
        t."Equi Name" as equi_name,
        t."Category" as category,
        t."Functional Location" as functional_location,
        t."Super Equi Id" as super_equi_id,
        t."Equi Type" as equi_type,
        t."Equi Class" as equi_class,
        try_cast(t."Weight kg" as decimal) as weight_kg,
        try(strptime(t."Startup Date", '%Y-%m-%d')::date) as startup_date,
        t."Manufacturer" as manufacturer,
        t."Model Number" as model_number,
        t."Manuf Part Number" as manuf_part_number,
        t."Manuf Serial Number" as manuf_serial_number,
        try_cast(t."Position" as integer) as position,
        t."Tech Ident Number" as tech_ident_number,
        t."User Status" as user_status,
        t."AI2 PLI Number" as ai2_pli_number,
        t."AI2 SAI Number" as ai2_sai_number,
        t."Location On Site" as location_on_site,
        t."Grid Ref" as grid_ref,
        try_cast(t."Easting" as integer) as easting,
        try_cast(t."Northing" as integer) as northing,
        t."Solution ID" as solution_id,
        t."Condition Grade" as condition_grade,
        t."Condition Grade Reason" as condition_grade_reason,
        try_cast(t."Survey Year" as integer) as survey_year,
    from cte1_raw t
) 
select * from cte2_typed
order by source_row;

