--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- `base_macros_catalog` is attached as `base_macros` (read_only)
-- The variables `source_xlsx` and `dest_dir` are set in 
-- DuckDb (i.e. not env vars)
--

.bail on
load excel;

set variable inputs = ['source_xlsx', 'dest_dir'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));

from base_macros.assert_databases_are_loaded(['base_macros']);


with cte1_raw as (
    select 
        base_macros.nulled(trim(columns(t.*))),
    from read_xlsx(
            $source_xlsx, 
            all_varchar=true) as t
), cte2_tidied as (
    select
        t."Manufacturer" AS manufacturer,
        t."Model Number" AS model,
    from cte1_raw t
), cte3_output as materialized (
    -- Write to `dest_dir`, file_name is fixed...
    copy (
        select * from cte2_tidied
        order by manufacturer, model
    ) to ($dest_dir || '/manuf_model_number.parquet') (format parquet, compression snappy)
)
select 'done' as ans;


select 'Wrote: ' || getvariable('dest_dir') || '/manuf_model_number.parquet' as result;

