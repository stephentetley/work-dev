


-- Preliminary: 
-- The variable `simple_floc_worklist` is set in DuckDb (i.e. not an env var)


-- Set the variable `simple_floc_worklist` before running this file

create or replace table simple_floc_landing.worklist as
select 
    *
from read_xlsx(
    getvariable('simple_floc_worklist'),
    all_varchar=true, 
    sheet='NewFloc'
) as t;

insert into simple_floc.worklist by name 
select 
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
    try_cast(t."Easting" as integer)as easting,
    try_cast(t."Northing" as integer) as northing,
    t."Solution ID" as solution_id,
from simple_floc_landing.worklist t
where t."Functional Location" is not null and t."Floc Name" is not null;



