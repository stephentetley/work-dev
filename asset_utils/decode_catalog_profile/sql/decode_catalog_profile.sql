--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminary: 
-- The variable `srcfile` is set in DuckDb (i.e. not an env var)
--
-- To get the source file print the list of Catalog profile choices
-- to a PDF in IH08. Export the file as plain text from Okular.


-- Set the variable `srcfile` before running this file

-- set variable srcfile = 'catalog_profile.txt';

create or replace temporary macro empty_as_null(str varchar) as
    case 
        when str = '' then null
        else str
    end;

create or replace temporary macro starts_with_time(str varchar) as
    regexp_matches(str, '^\s+\d{1,2}:\d{2}:\d{2}');

create or replace temporary macro starts_with_date(str varchar) as
    regexp_matches(str, '^\p{L}{3} \p{L}{3} \d{1,2}');


create or replace temporary macro get_cat_prof(str varchar) as
    case starts_with_time(str)
        when true then null
        else coalesce(
                regexp_extract(str, '^\s+(\S+)\s+', 1).empty_as_null(),
                regexp_extract(str, '^\p{L}{3} \p{L}{3} \d{1,2}(\S+)$', 1).empty_as_null()
            )
    end;

create or replace temporary macro get_description(str varchar) as
    case starts_with_date(str)
        when true then null
        else coalesce(
                regexp_extract(str, '^\s+\d{1,2}:\d{2}:\d{2} \d{4}(.+)\s+\d+/\d+$', 1).trim().empty_as_null(),
                regexp_extract(str, '^\s+\S+\s+(.+)', 1).empty_as_null()
            )
    end;

create or replace table xtable_catalog_profile_classes as
with cte1_raw as (
    select 
        row_number() over () as linenum,
        t.* as body,
    from read_csv(getvariable(srcfile), header=false) t
), cte2_build_rows as (
    select 
        t.linenum,
        get_cat_prof(t.body) as cat_prof,
        get_description(t.body) as description,
    from cte1_raw t
    where not regexp_matches(t.body, 'Catalog profile text')
), cte3_with_prev as (
    select 
        t.linenum,
        t.cat_prof,
        t.description,
        lag(t.cat_prof, 1) over (order by t.linenum) as prev_cat_prof
    from cte2_build_rows t
), cte4_fixup as (
    select 
        t.linenum,
        coalesce(t.cat_prof, t.prev_cat_prof) as cat_prof,
        t.description,
    from cte3_with_prev t
    where t.description is not null
)
select cat_prof, description from cte4_fixup;
