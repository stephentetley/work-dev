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
        trim(columns(t.*)),
    from read_xlsx(
            $source_xlsx, 
            sheet='inst to SAP migration',
            all_varchar=true) as t
), cte2_tidied as (
    select
        t."AI2_SiteReference" AS ai2_site_id,  
        t."SITE_NAME" AS ai2_site_name,  
        t."AI2_InstallationReference" AS ai2_installation_id,
        t."AI2_InstallationCommonName" AS ai2_installation_name,
        t."S/4 Hana Floc Lvl1_Code" AS s4_site_funcloc,
        t."S/4 Hana Floc Description" AS s4_site_name,
        t."Asset Status 02/01/2025" AS asset_status, 
    from cte1_raw t
), cte3_output as materialized (
    -- Write to `dest_dir`, file_name is fixed...
    copy (
        select * from cte2_tidied
        order by s4_site_funcloc, ai2_installation_id
    ) to ($dest_dir || '/site_mapping.parquet') (format parquet, compression snappy)
)
select 'done' as ans;

select 'Wrote: ' || $dest_dir || '/site_mapping.parquet' as result;

