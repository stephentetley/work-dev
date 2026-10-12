--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `source_json_dir` and `dest_path` are set in 
-- DuckDb (i.e. not env vars)
--
-- The As Fitted reports hae already been converted from xlsx
-- to json (by a separate program, too complicated to do in SQL).
--

create or replace temporary macro nulled(str varchar) as 
    if(str == '' or upper(str) == 'NULL', null, str);

create or replace temporary macro norm_text(str varchar) as
    trim(str).regexp_replace('\s+', ' ', 'g').nulled();

create or replace macro make_search_glob() as
    getvariable('source_json_dir') || '/*.json';

create or replace table table1 as
select 
    norm_text(columns(* exclude(checklist_year))),
    checklist_year as checklist_year,
from read_json(
    make_search_glob()
);

-- Don't fix the output table name...
copy (
    select * from table1
) to (getvariable('dest_path')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_path') as result;

