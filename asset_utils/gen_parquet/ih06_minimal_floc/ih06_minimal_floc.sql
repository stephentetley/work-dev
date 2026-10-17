--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `source_xlsx` and `dest_parquet` are set in 
-- DuckDb (i.e. not env vars)
--

.bail on
load excel;

with cte1_variables as (
select 
    ifnull(getvariable('source_xlsx'), error('Must set variable "source_xlsx"')) as source_xlsx,
    ifnull(getvariable('dest_parquet'), error('Must set variable "dest_parquet"')) as dest_parquet,
)
unpivot cte1_variables
on columns(*)
into name variable value value;



create or replace temporary macro nulled(str varchar) as 
    if(str == '' or upper(str) == 'NULL', null, str);

create or replace temporary table table1 as
with cte1_raw as (
    select 
        nulled(trim(columns(t.*))),
    from read_xlsx(
            getvariable('source_xlsx'), 
            sheet='Sheet1',
            all_varchar=true) as t
)
select * from cte1_raw;

alter table table1 add column if not exists "Easting" varchar default null;
alter table table1 add column if not exists "Northing" varchar default null;
alter table table1 add column if not exists "AI2 AIB Reference" varchar default null;

create or replace temporary view vw_table1 as
select 
    t."Functional Location" as functional_location,
    max(t."Description of functional location") as floc_name,
    max(try_cast(t."FunctLocCategory" as integer)) as floc_category,
    max(t."Structure indicator") as str_indicator,
    max(t."Object Type") as floc_type,
    max(try_cast(excel_text(try_cast(t."Start-up date" as decimal), 'yyyy-mm-dd') as date)) as startup_date,
    max(try_cast(t."Position in object" as integer)) as position,
    max(try_cast(t."Maintenance Plant" as integer)) as maint_plant,
    max(try_cast(t."Cost Center" as integer)) as cost_center,
    max(t."Main Work Center") as main_work_center,
    max(t."Plant Section") as plant_section,
    max(upper(t."Installation allowed") == 'X') as installation_allowed,
    max(t."User Status") as user_status,
    max(try_cast(t."Easting" as integer)) as easting,
    max(try_cast(t."Northing" as integer)) as northing,
    list("AI2 AIB Reference" order by "AI2 AIB Reference" asc) filter ("AI2 AIB Reference" is not null) as aib_numbers
from table1 t
group by all;

-- Don't fix the output table name, user defined...
copy (
    select * from vw_table1 order by functional_location
) to (getvariable('dest_parquet')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_parquet') as result;

