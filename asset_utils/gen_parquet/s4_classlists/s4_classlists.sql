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

-- Uses `last` window function to fill elided data downwards

.bail on
load excel;

create or replace temporary macro nulled(str varchar) as 
    if(str == '', null, str);


create or replace temporary table temp1 as
with cte1_raw as (
    select 
        row_number() over () as row_ix,
        nulled(trim(columns(*))),
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
)
select * from cte3_filled;

create or replace temporary view class_chars as
select
    t.class_name_filled as class_name,
    t.char_name as char_name,
    t.class_description_filled as class_description,
    t.char_description_filled as char_description,
    t.data_type as char_type,
    t.char_length as char_length,
    t.char_precision as char_precision,
from temp1 t
where t.char_name is not null;

create or replace temporary view char_enums as 
select
    t.class_name_filled as class_name,
    t.char_name_filled as char_name,
    t.char_value as enum_value,
    t.enum_description as enum_description,
from temp1 t
where t.char_value is not null;

-- Floc and Equi have the same format
-- We use the source file name to decide what we are looking at.

create or replace temporary macro make_classlist_name() as 
    case 
        when getvariable('source_xlsx') like '%floc%' then getvariable('dest_dir') || '/s4_floc_classlist.parquet'
        when getvariable('source_xlsx') like '%equi%' then getvariable('dest_dir') || '/s4_equi_classlist.parquet'
        else null
    end;

copy (
    select * from class_chars
    order by #1, #2, #3
) to (make_classlist_name()) (format parquet, compression snappy);

select 'Wrote: ' || make_classlist_name() as result;

create or replace temporary macro make_enums_name() as 
    case 
        when getvariable('source_xlsx') like '%floc%' then getvariable('dest_dir') || '/s4_floc_enums.parquet'
        when getvariable('source_xlsx') like '%equi%' then getvariable('dest_dir') || '/s4_equi_enums.parquet'
        else null
    end;


copy (
    select * from char_enums
    order by #1, #2, #3
) to (make_enums_name()) (format parquet, compression snappy);

select 'Wrote: ' || make_enums_name() as result;

