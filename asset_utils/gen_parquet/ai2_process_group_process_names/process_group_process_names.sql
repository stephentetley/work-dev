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



create or replace temporary macro nulled(str varchar) as 
    if(str == '' or upper(str) == 'NULL', null, str);


create or replace temporary table process_group as
with cte1_raw as (
    select 
        nulled(trim(columns(t.*))),
    from read_xlsx(
            getvariable('source_xlsx'),
            sheet='process_group', 
            all_varchar=true) as t
), cte2_with_columns_no_dups as (
    select
        t."ProcessGroupAssetTypeDescription" as process_group_name,
    from cte1_raw t
    where t."ProcessGroupAssetTypeDescription" is not null
    group by all
)
select * from cte2_with_columns_no_dups;

copy (
    select * from process_group
    order by process_group_name
) to (getvariable('dest_dir') || '/process_group_names.parquet') (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_dir') || '/process_group_names.parquet' as result;

create or replace temporary table process as
with cte1_raw as (
    select 
        nulled(trim(columns(t.*))),
    from read_xlsx(
            getvariable('source_xlsx'),
            sheet='process', 
            all_varchar=true) as t
), cte2_with_columns_no_dups as (
    select
        t."ProcessAssetTypeDescription" as process_name,
    from cte1_raw t
    where t."ProcessAssetTypeDescription" is not null
    group by all
)
select * from cte2_with_columns_no_dups;


-- Write to `dest_dir`, file_name is fixed...
copy (
    select * from process
    order by process_name
) to (getvariable('dest_dir') || '/process_names.parquet') (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_dir') || '/process_names.parquet' as result;
