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

from base_macros.assert_databases_are_loaded(['base_macros']);

-- SET GLOBAL table_function_identifier_conversion = 'DISABLE_IMPLICIT_STRING';

-- Copied text from Okular may have 2 or 3 tabs (2 if column 3 is blank)
-- This cause a parse error for the csv parser


with cte1_raw as (
    select 
        t.content,
    from read_text($source_txt) t
), cte2_lines as (
    select 
        unnest(array_pop_front(regexp_split_to_array(t.content, E'\n'))) as textline
    from cte1_raw t
), cte3_numbered_lines as (
    select
        row_number() over () as row_ix,
        regexp_split_to_array(t.textline, E'\t') as arr, 
    from cte2_lines t
), cte4_filtered as (
    select
        row_ix,
        base_macros.nulled(trim(arr[1])) as description,
        base_macros.nulled(trim(arr[2])) as medium,
        if(length(arr) == 3, base_macros.nulled(trim(arr[3])), null) as short,
    from cte3_numbered_lines t
    where length(arr) >= 2
), cte5_output as materialized (
    -- Write to `dest_dir`, file_name is fixed...
    copy (
        select * from cte4_filtered
        order by medium
    ) to ($dest_dir || '/rts_abbreviations.parquet') (format parquet, compression snappy)
)
select 'done' as ans;


select 'Wrote: ' || $dest_dir || '/rts_abbreviations.parquet' as result;