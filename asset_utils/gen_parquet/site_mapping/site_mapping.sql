--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `source_xlsx` and `dest_dir` are set in 
-- DuckDb (i.e. not env vars)
--

.bail on
load excel;

with cte1_variables as (
select 
    ifnull(getvariable('source_xlsx'), error('Must set variable "source_xlsx"')) as source_xlsx,
    ifnull(getvariable('dest_dir'), error('Must set variable "dest_dir"')) as dest_dir,
)
unpivot cte1_variables
on columns(*)
into name variable value value;


create or replace temporary table table1 as
with cte1_raw as (
    select 
        trim(columns(t.*)),
    from read_xlsx(
            getvariable('source_xlsx'), 
            sheet='inst to SAP migration',
            all_varchar=true) as t
)
select
    t."AI2_SiteReference" AS ai2_site_id,  
    t."SITE_NAME" AS ai2_site_name,  
    t."AI2_InstallationReference" AS ai2_installation_id,
    t."AI2_InstallationCommonName" AS ai2_installation_name,
    t."S/4 Hana Floc Lvl1_Code" AS s4_site_funcloc,
    t."S/4 Hana Floc Description" AS s4_site_name,
    t."Asset Status 02/01/2025" AS asset_status, 
from cte1_raw t;


-- Write to `dest_dir`, file_name is fixed...
copy (
    select * from table1
    order by s4_site_funcloc, ai2_installation_id
) to (getvariable('dest_dir') || '/site_mapping.parquet') (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_dir') || '/site_mapping.parquet' as result;

