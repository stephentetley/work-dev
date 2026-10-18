--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- `base_macros_catalog` is attached as `base_macros` (read_only)
-- The variables `source_ih08_xlsx` and `dest_minimal_equi_parquet` are set in 
-- DuckDb (i.e. not env vars)
--

.bail on
load excel;

set variable inputs = ['source_ih08_xlsx', 'dest_minimal_equi_parquet'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));



create or replace temporary table table1 as
with cte1_raw as (
    select 
        base_macros.nulled(trim(columns(t.*))),
    from read_xlsx(
            getvariable('source_ih08_xlsx'), 
            sheet='Sheet1',
            all_varchar=true) as t
)
select * from cte1_raw;

alter table table1 add column if not exists "Easting" varchar default null;
alter table table1 add column if not exists "Northing" varchar default null;
alter table table1 add column if not exists "AI2 AIB Reference" varchar default null;

create or replace temporary view vw_table1 as
select 
    t."Equipment" as equi_id,
    max(t."Description of technical object") as equi_name,
    max(t."Equipment category") as equi_category,
    max(t."Functional Location") as functional_location,
    max(t."Superord. Equipment") as parent_equi,
    max(t."Object Type") as equi_type,
    max(t."Standard Class") as standard_class,
    max(try_cast(t."Gross Weight" as integer)) as gross_weight,
    max(t."Unit of Weight") as unit_of_weight,
    max(try_cast(excel_text(try_cast(t."Start-up date" as decimal), 'yyyy-mm-dd') as date)) as startup_date,
    max(t."Manufacturer of Asset") as manufacturer,
    max(t."Model number") as model,
    max(t."Manufacturer part number") as part_number,
    max(t."Manufacturer's Serial Number") as serial_number,
    max(try_cast(t."Position" as integer)) as position,
    max(t."Technical identification no.") as tech_ident_num,
    max(t."User Status") as user_status,
    max(try_cast(t."Maintenance Plant" as integer)) as maint_plant,
    max(try_cast(t."Cost Center" as integer)) as cost_center,
    max(t."Main Work Center") as main_work_center,
    max(try_cast(t."Easting" as integer)) as easting,
    max(try_cast(t."Northing" as integer)) as northing,
    list("AI2 AIB Reference" order by "AI2 AIB Reference" asc) filter ("AI2 AIB Reference" is not null) as aib_numbers
from table1 t
group by all;

-- Don't fix the output table name, user defined...
copy (
    select * from vw_table1 order by functional_location
) to (getvariable('dest_minimal_equi_parquet')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_minimal_equi_parquet') as result;

