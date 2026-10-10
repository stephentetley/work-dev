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

create or replace temporary macro nulled(str varchar) as 
    if(str == '' or upper(str) == 'NULL', null, str);

create or replace temporary table table1 as
with cte1_raw as (
    select 
        nulled(trim(columns(t.*))),
    from read_xlsx(
            getvariable('source_xlsx'), 
            sheet='Class and Char_All',
            all_varchar=true) as t
), cte2_columns_defined as (
    select
        t."Class" as equiclass,
        t."Class Description (40)" as equiclass_description,
        t."Category Code" as category,
    from cte1_raw t
    where t."Class Type" == '002'
    and t."Data Entity" == 'Equip'
    and t."Category Code" is not null
), cte3_no_dups as (
    select 
        t.equiclass,
        max(t.equiclass_description) as equiclass_description,
        max(t.category) as category,
        list(distinct t.category order by t.category) as all_categories,
    from cte2_columns_defined t
    group by all
) 
select * from cte3_no_dups;

copy (
    select * from table1
    order by equiclass
) to (getvariable('dest_dir') || '/equiclass_to_category_mapping.parquet') (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_dir') || '/equiclass_to_category_mapping.parquet' as result;

