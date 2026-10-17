--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `source_xlsx` and `dest_dir` are set in 
-- DuckDb (i.e. not env vars)
--

.bail on
load excel;

with cte1_variables as (
select 
    ifnull(getvariable('source_xlsx'), error('Must set variable "source_xlsx"')) as source_xlsx,
    ifnull(getvariable('dest_dir'), error('Must set variable "dest_dir"')) as dest_dir,
)
unpivot cte1_variables
on columns(*)
into name variable value value;

create or replace temporary table table1 as
with cte1_raw as (
    select 
        trim(columns(t.*)),
    from read_xlsx(
            getvariable('source_xlsx'), 
            all_varchar=true) as t
)
select
    t."Object Type" AS object_type,
    t."Manufacturer" AS manufacturer,
    t."Remarks" AS remarks,
from cte1_raw t;

-- Write to `dest_dir`, file_name is fixed...
copy (
    select * from table1
    order by object_type, manufacturer
) to (getvariable('dest_dir') || '/equi_object_type_manuf.parquet') (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_dir') || '/equi_object_type_manuf.parquet' as result;

