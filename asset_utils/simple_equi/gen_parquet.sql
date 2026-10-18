--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `simple_equi_xlsx` and `dest_simple_equi_parquet` are set in 
-- DuckDb (i.e. not env vars)
--

.bail on
load excel;

with cte1_variables as (
select 
    ifnull(getvariable('simple_equi_xlsx'), error('Must set variable "simple_equi_xlsx"')) as simple_equi_xlsx,
    ifnull(getvariable('dest_simple_equi_parquet'), error('Must set variable "dest_simple_equi_parquet"')) as dest_simple_equi_parquet,
)
unpivot cte1_variables
on columns(*)
into name variable value value;




create or replace temporary table table1 as
with cte1_raw as (
    select 
        base_macros.nulled(trim(columns(t.*))),
    from read_xlsx(
        getvariable('simple_equi_xlsx'),
        all_varchar=true, 
        sheet='NewEqui'
    ) as t
)
select 
    try_cast(t."Batch Number" as integer) as batch_number,
    t."Temp ID" as temp_id,
    t."Equi Name" as equi_name,
    t."Category" as equi_category,
    t."Functional Location" as functional_location,
    t."Super Equi Id" as super_equi_id,
    t."Equi Type" as equi_type,
    t."Equi Class" as equi_class,
    try_cast(t."Weight kg" as decimal) as weight_kg,
    strptime(t."Startup Date", '%d.%m.%Y') as startup_date,
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
where t."Temp ID" is not null and t."Equi Name" is not null;


-- Don't fix the output table name, user defined...
copy (
    select * from table1 order by batch_number, functional_location, temp_id
) to (getvariable('dest_simple_equi_parquet')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_simple_equi_parquet') as result;

