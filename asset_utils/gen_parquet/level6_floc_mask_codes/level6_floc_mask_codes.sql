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

create or replace temporary macro make_num_fstring(hashes varchar) as 
    case length(hashes)
        when 2 then '{:02d}'
        when 2 then '{:03d}'
        else '{d}'
    end;

create or replace temporary macro make_fstring(mask_code varchar) as 
    regexp_extract(mask_code, '^(\p{L}+)#+$', 1) 
        || make_num_fstring(regexp_extract(mask_code, '^\p{L}+(#+)$', 1));

create or replace temporary table table1 as
with cte1_raw as (
    select 
        trim(columns(t.*)),
    from read_xlsx(
            getvariable('source_xlsx'), 
            all_varchar=true) as t
), cte2_columns_defined as (
    select
        t."Object" as object_type,
        t."Object Code Description" as object_type_desription,
        t."FLOC Mask Hierarchical Code" as mask_code,
        make_fstring(t."FLOC Mask Hierarchical Code") as fstring,
    from cte1_raw t
), cte3_no_dups as (
    select
        t.object_type,
        any_value(t.object_type_desription),
        max(t.mask_code),
        max(t.fstring),
    from cte2_columns_defined t
    group by t.object_type
)
select * from cte3_no_dups;

copy (
    select * from table1
    order by object_type
) to (getvariable('dest_dir') || '/level6_floc_mask_codes.parquet') (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_dir') || '/level6_floc_mask_codes.parquet' as result;

