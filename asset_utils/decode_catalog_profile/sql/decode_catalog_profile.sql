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

create or replace table xtable_catalog_profile_classes as
with cte1_raw as (
    select 
        row_number() over () as linenum,
        t.* as body,
    from read_csv(getvariable(srcfile), header=false) t
), cte2_drop_page_headings as (
    select 
        t.* 
    from cte1_raw t
    where not regexp_matches(t.body, 'Catalog profile text')
), cte3_good_lines as (
    select 
        t.linenum, 
        regexp_extract(t.body, '^\s+(\p{Lu}{6})\s+(.+)$', 1) as class_name,
        regexp_extract(t.body, '^\s+(\p{Lu}{6})\s+(.+)$', 2) as description,
    from cte2_drop_page_headings t
    where regexp_matches(t.body, '^\s+(\p{Lu}{6})\s+(.+)$')
), cte4_page_number_lines as (
    select 
        t.linenum, 
        'FROM_PREV' as class_name,
        regexp_extract(t.body, '^\s+\d{1,2}:\d{2}:\d{2} \d{4}(.+)\s+\d+/\d+$', 1) as description,
    from cte2_drop_page_headings t
    where regexp_matches(t.body, '^\s+\d{1,2}:\d{2}:\d{2} \d{4}(.+)\s+\d+/\d+$') -- \s+\d:\d:\d \d{4}(.+)
), cte5_starts_with_date_lines as (
    select 
        t.linenum, 
        regexp_extract(t.body, '^\p{L}{3} \p{L}{3} \d{1,2}(\p{Lu}{6})$', 1) as class_name,
        'FROM NEXT' as description,
    from cte2_drop_page_headings t
    where regexp_matches(t.body, '^\p{L}{3} \p{L}{3} \d{1,2}(\p{Lu}{6})$')
), cte6_line_break_stitching as (
    select
        t.linenum, 
        t.class_name, 
        t1.description,
    from cte5_starts_with_date_lines t
    join cte4_page_number_lines t1 on t1.linenum = t.linenum + 1 
), cte7_unions as (
    select t.class_name, t.description from cte3_good_lines t
    union by name 
    select t.class_name, t.description from cte6_line_break_stitching t
)
select * from cte7_unions
order by class_name;
