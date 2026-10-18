--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- To get the source file print the list of Catalog profile choices
-- to a PDF in IH08. Export the file as plain text from Okular.


-- Preliminaries: 
-- `base_macros_catalog` is attached as `base_macros` (read_only)
-- The variables `source_txt` and `dest_dir` are set in 
-- DuckDb (i.e. not env vars)
--
-- `source_txt` is extracted from Okular manually (page by page) 
-- with the table tool. The alternative `Export as >> Palin text`
-- was very difficult to accurately parse.
--

.bail on
load excel;

set variable inputs = ['source_txt', 'dest_dir'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));


-- Copied text from Okular may have 2 or 3 tabs (2 if column 3 is blank)
-- This cause a parse error for the csv parser
create or replace temporary table table1 as
with cte1_raw as (
    select 
        t.content,
    from read_text(getvariable(source_txt)) t
), cte2_lines as (
    select 
        unnest(array_pop_front(regexp_split_to_array(t.content, '\n'))) as textline
    from cte1_raw t
), cte3_numbered_lines as (
    select
        row_number() over () as row_ix,
        regexp_split_to_array(t.textline, '\t') as arr, 
    from cte2_lines t
), cte4_filtered as (
    select
        row_ix,
        trim(arr[1]).nulled() as description,
        trim(arr[2]).nulled() as medium,
        if(length(arr) == 3, trim(arr[3]).nulled(), null) as short,
    from cte3_numbered_lines t
    where length(arr) >= 2
)
select * from cte4_filtered;

-- Write to `dest_dir`, file_name is fixed...
copy (
    select * from table1
    order by medium
) to (getvariable('dest_dir') || '/rts_abbreviations.parquet') (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_dir') || '/rts_abbreviations.parquet' as result;