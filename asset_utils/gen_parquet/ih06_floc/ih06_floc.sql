--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `source_xlsx` and `dest_path` are set in 
-- DuckDb (i.e. not env vars)
--

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


create or replace temporary view vw_table1 as
select 
    t."Functional Location" as functional_location,
    t."Description of functional location" as floc_name,
    try_cast(t."FunctLocCategory" as integer) as floc_category,
    t."Structure indicator" as str_indicator,
    t."Object Type" as floc_type,
    excel_text(try_cast(t."Start-up date" as decimal), 'yyyy-mm-dd') as startup_date,
    try_cast(t."Position in object" as integer) as position,
    try_cast(t."Maintenance Plant" as integer) as maint_plant,
    try_cast(t."Cost Center" as integer) as cost_center,
    t."Main Work Center" as main_work_center,
    t."Plant Section" as plant_section,
    upper(t."Installation allowed") == 'X' as installation_allowed,
    t."User Status" as user_status,
    try_cast(t."Easting" as integer) as easting,
    try_cast(t."Northing" as integer) as northing,
from table1 t;

-- Don't fix the output table name...
copy (
    select * from vw_table1
) to (getvariable('dest_path')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_path') as result;

