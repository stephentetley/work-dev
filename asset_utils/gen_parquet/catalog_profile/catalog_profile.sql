--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- To get the source file print the list of Catalog profile choices
-- to a PDF in IH08. Export the file as plain text from Okular.


-- Preliminaries: 
-- The variables `source_txt` and `dest_dir` are set in 
-- DuckDb (i.e. not env vars)
--

.bail on
load excel;

create or replace temporary macro nulled(str varchar) as 
    if(str == '' or upper(str) == 'NULL', null, str);


create or replace temporary macro starts_with_time(str varchar) as
    regexp_matches(str, '^\s+\d{1,2}:\d{2}:\d{2}');

create or replace temporary macro starts_with_date(str varchar) as
    regexp_matches(str, '^\p{L}{3} \p{L}{3} \d{1,2}');


create or replace temporary macro get_cat_prof(str varchar) as
    case starts_with_time(str)
        when true then null
        else coalesce(
                regexp_extract(str, '^\s+(\S+)\s+', 1).nulled(),
                regexp_extract(str, '^\p{L}{3} \p{L}{3} \d{1,2}(\S+)$', 1).nulled()
            )
    end;

create or replace temporary macro get_description(str varchar) as
    case starts_with_date(str)
        when true then null
        else coalesce(
                regexp_extract(str, '^\s+\d{1,2}:\d{2}:\d{2} \d{4}(.+)\s+\d+/\d+$', 1).trim().nulled(),
                regexp_extract(str, '^\s+\S+\s+(.+)', 1).nulled()
            )
    end;

create or replace table table1 as
with cte1_raw as (
    select 
        row_number() over () as row_ix,
        -- preserve leading and trailing spaces...
        t.line as body,
    from read_csv(
        getvariable(source_txt), 
        header=false, 
        delim = '~',
        columns = {
            'line' : 'varchar'
        }) t
), cte2_build_rows as (
    select 
        t.row_ix,
        get_cat_prof(t.body) as cat_prof,
        get_description(t.body) as description,
    from cte1_raw t
    where not regexp_matches(t.body, 'Catalog profile text')
), cte3_with_prev as (
    select 
        t.row_ix,
        t.cat_prof,
        t.description,
        lag(t.cat_prof, 1) over (order by t.row_ix) as prev_cat_prof
    from cte2_build_rows t
), cte4_fixup as (
    select 
        t.row_ix,
        coalesce(t.cat_prof, t.prev_cat_prof) as cat_prof,
        t.description,
    from cte3_with_prev t
    where t.description is not null
)
select cat_prof, description from cte4_fixup;



copy (
    select * from table1
    order by cat_prof
) to (getvariable('dest_dir') || '/catalog_profile.parquet') (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_dir') || '/catalog_profile.parquet' as result;
