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

with cte1_variables as (
select 
    ifnull(getvariable('source_json_dir'), error('Must set variable "source_json_dir"')) as source_json_dir,
    ifnull(getvariable('dest_path'), error('Must set variable "dest_path"')) as dest_path,
)
unpivot cte1_variables
on columns(*)
into name variable value value;


create or replace temporary macro nulled(str varchar) as 
    if(str == '' or upper(str) == 'NULL', null, str);

create or replace temporary macro norm_text(str varchar) as
    trim(str).regexp_replace('\s+', ' ', 'g').nulled();

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

