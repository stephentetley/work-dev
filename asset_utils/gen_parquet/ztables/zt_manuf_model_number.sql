--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `source_xlsx` and `dest_parquet` are set in 
-- DuckDb (i.e. not env vars)
--

.bail on
load excel;

create or replace temporary table temp1 as
with cte1_raw as (
    select 
        trim(columns(t.*)),
    from read_xlsx(
            getvariable('source_xlsx'), 
            all_varchar=true) as t
)
select
    t."Manufacturer" AS 'manufacturer',
    t."Model Number" AS 'model',
from cte1_raw t;

copy (
    select * from temp1
    order by manufacturer, model
) to (getvariable('dest_parquet')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_parquet') as result;

