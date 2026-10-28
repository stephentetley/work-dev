--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- `base_macros_catalog` is attached as `base_macros` (read_only)
-- The variables `source_ih06_xlsx` and `dest_minimal_floc_parquet` are set in 
-- DuckDB (i.e. not env vars)
--

.bail on
load excel;

set variable inputs = ['xlsx_source_glob', 'parquet_dest_folder'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));
from base_macros.assert_env_vars_are_set(['WORK_DEV_ROOT']);


set variable xlsx_source_glob = '*.xlsx';

create or replace temporary table table1 as
with cte1_raw as (
    select
        row_number() over () as row_ix,
        file,
    from glob(getvariable('xlsx_source_glob'))
), cte2_commands as (
    select
        format('set variable source_ai2_xlsx = ''{}'';', file) as set_source,
        format('set variable dest_ai2_parquet = ''{}/ai2_export_{:03d}.parquet'';', $parquet_dest_folder, row_ix) as set_dest,
        format('.read ''{}/asset_utils/gen_parquet/ai2_export/ai2_export.sql''', getenv('WORK_DEV_ROOT')) as run_script,
    from cte1_raw
)
select concat_ws(E'\n', set_source, set_dest, run_script, E'\n') as sql_text from cte2_commands;

copy (select sql_text from table1)
to 'ai2_exports_to_parquet_generated.sql' (format csv, header false, quote '');

.print "Wrote - ai2_exports_to_parquet_generated.sql"