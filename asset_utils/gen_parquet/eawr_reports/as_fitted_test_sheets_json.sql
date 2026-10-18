--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- `base_macros_catalog` is attached as `base_macros` (read_only)
-- The variables `source_json_dir` and `dest_path` are set in 
-- DuckDb (i.e. not env vars)
--
-- The As Fitted reports have already been converted from xlsx
-- to json (by a separate program, too complicated to do in SQL).
--


.bail on
load excel;

set variable inputs = ['source_json_dir', 'dest_path'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));



create or replace temporary macro norm_text(str varchar) as
    base_macros.nulled(trim(str).regexp_replace('\s+', ' ', 'g'));

create or replace temporary macro make_search_glob() as
    getvariable('source_json_dir') || '/*.json';

create or replace temporary table table1 as
select 
    norm_text(columns(* exclude(checklist_year))),
    checklist_year as checklist_year,
from read_json(
    make_search_glob()
);

-- Don't fix the output table name, expect multiple runs...
copy (
    select * from table1
) to (getvariable('dest_path')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_path') as result;

