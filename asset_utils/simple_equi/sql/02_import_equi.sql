


-- Preliminary: 
-- The variable `simple_equi_worklist` is set in DuckDb (i.e. not an env var)


-- Set the variable `simple_equi_worklist` before running this file

create or replace table simple_equi_landing.worklist as
select 
    *
from read_xlsx(
    getvariable('simple_equi_worklist'),
    all_varchar=true, 
    sheet='NewEqui'
) as t;

insert into simple_equi.worklist by name 
select 
    t."Temp ID" as temp_id,
    t."Equi Name" as equi_name,
    t."Category" as equi_category,
    t."Functional Location" as functional_location,
    t."Super Equi Id" as super_equi_id,
    t."Equi Type" as equi_type,
    t."Equi Class" as equi_class,
    try_cast(t."Weight kg" as decimal) as weight_kg,
    t."Startup Date" as startup_date,
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
    try_cast(t."Easting" as integer)as easting,
    try_cast(t."Northing" as integer) as northing,
    t."Solution ID" as solution_id,
    t."Condition Grade" as condition_grade,
    t."Condition Grade Reason" as condition_grade_reason,
    try_cast(t."Survey Year" as integer) as survey_year,
from simple_equi_landing.worklist t
where t."Temp ID" is not null and t."Equi Name" is not null;



