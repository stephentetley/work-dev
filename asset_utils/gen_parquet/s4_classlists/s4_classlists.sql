--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- `base_macros_catalog` is attached as `base_macros` (read_only)
-- The variables `source_xlsx` and `dest_dir` are set in 
-- DuckDb (i.e. not env vars)
--

-- Uses `last` window function to fill elided data downwards

.bail on
load excel;

set variable inputs = ['source_xlsx', 'dest_dir'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));

from base_macros.assert_databases_are_loaded(['base_macros']);


create or replace temporary macro get_ddl_data_type(char_type varchar, num_length integer, num_prec integer) as (
with cte1_params as (
    select 
        coalesce(char_type, 'varchar').lower() as typ,
        coalesce(num_length, 10) as len,
        coalesce(num_prec, 0) as prec,
)
select 
    case 
        when t.typ = 'char' then 'varchar'
        when t.typ = 'enum' then 'varchar'
        when t.typ = 'num' and t.prec > 0 then format('decimal({}, {})', t.len, t.prec)
        when t.typ = 'num' and t.len < 10 and t.prec = 0 then 'integer'
        when t.typ = 'num' and t.len >= 10 and t.len < 19 and t.prec = 0  then 'bigint'
        when t.typ = 'num' and t.len >= 19 and t.prec = 0 then 'hugeint'
        else t.typ
    end
from cte1_params t);


-- Floc and Equi have the same format
-- We use the source file name to decide what we are looking at.

create or replace temporary macro make_classlist_name(source varchar) as 
case 
    when lower(source) like '%floc%' then '/floc_classlist.parquet'
    when lower(source) like '%equi%' then '/equi_classlist.parquet'
    else null
end;

create or replace temporary macro make_enums_name(source varchar) as 
case 
    when lower(source) like '%floc%' then '/floc_enums.parquet'
    when lower(source) like '%equi%' then '/equi_enums.parquet'
    else null
end;



with cte1_raw as (
    select 
        row_number() over () as row_ix,
        base_macros.nulled(trim(columns(*))),
    from read_xlsx(
            getvariable('source_xlsx'), 
            sheet='Sheet1',
            all_varchar=true) as t
), cte2_named_columns as (
    select
        row_ix,
        regexp_replace(#3, '\d{3} ', '') AS class_name,
        #4 AS char_name,
        #5 AS char_value,
        if(#3 is not null, #6, null) AS class_description,
        if(#4 is not null, #6, null) AS char_description,
        if(#5 is not null, #6, null) AS enum_description,
        #8 AS data_type,
        #9 AS char_length,
        #10 AS char_precision,
    from cte1_raw
    where class_name is not null
        or char_name is not null
        or char_value is not null
), cte3_filled as (
    select
        *,
        last(class_name ignore nulls) over (order by row_ix) as class_name_filled,
        last(char_name ignore nulls) over (order by row_ix) as char_name_filled,
        last(class_description ignore nulls) over (order by row_ix) as class_description_filled,
        last(char_description ignore nulls) over (order by row_ix) as char_description_filled,
    from cte2_named_columns
), cte4_class_chars as (
    select
        row_number() over (partition by class_name_filled order by row_ix)  as char_ix,
        t.class_name_filled as class_name,
        t.char_name as char_name,
        t.class_description_filled as class_description,
        t.char_description_filled as char_description,
        t.data_type as char_type,
        t.char_length as char_length,
        t.char_precision as char_precision,
        get_ddl_data_type(t.data_type, t.char_length::integer, t.char_precision::integer) as ddl_data_type,
    from cte3_filled t
    where t.char_name is not null
), cte5_output_chars as materialized (
    copy (
        select * from cte4_class_chars
        order by class_name, char_ix
    ) to ($dest_dir || make_classlist_name($source_xlsx)) (format parquet, compression snappy)
), cte6_char_enums as (
    select
        row_number() over (partition by class_name_filled, char_name_filled order by row_ix)  as enum_ix,
        t.class_name_filled as class_name,
        t.char_name_filled as char_name,
        t.char_value as enum_value,
        t.enum_description as enum_description,
    from cte3_filled t
    where t.char_value is not null
), cte7_output_enums as materialized (
    -- Don't fix the output table name, expect two runs (floc and equi)...
    copy (
        select * from cte6_char_enums
        order by class_name, char_name, enum_ix
    ) to ($dest_dir || make_enums_name($source_xlsx)) (format parquet, compression snappy)
)
select 'done' as ans;

select 'Wrote: ' || make_classlist_name($source_xlsx) as result;
select 'Wrote: ' || make_enums_name($source_xlsx) as result;

