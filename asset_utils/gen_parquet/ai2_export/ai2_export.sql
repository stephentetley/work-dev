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

set variable inputs = ['source_ai2_xlsx', 'dest_ai2_parquet'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));

from base_macros.assert_databases_are_loaded(['base_macros']);

create or replace temporary table table1 as
with cte1_raw as (
    select 
        base_macros.nulled(trim(columns(t.*))),
    from read_xlsx(
            getvariable('source_ai2_xlsx'), 
            sheet='Sheet1',
            all_varchar=true) as t
), cte2_partial_renaming as (
    select
        * exclude (t."AssetId", t."Asset in AIDE ?", t."Installed From")
          rename (t."Reference" as pli_num,
                    t."Common Name" as common_name,
                    t."Manufacturer" as manufacturer, 
                    t."Model" as model, 
                    t."Hierarchy Key" as hierarchy_key, 
                    t."AssetStatus" as asset_status, 
                    t."Loc.Ref." as loc_ref),
        try_cast(excel_text(try_cast(t."Installed From" as decimal), 'yyyy-mm-dd') as date) as installed_from,
    from cte1_raw t
)
select * from cte2_partial_renaming;


-- Don't fix the output table name, user defined...
copy (
    select * from table1 order by common_name
) to (getvariable('dest_ai2_parquet')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_ai2_parquet') as result;

