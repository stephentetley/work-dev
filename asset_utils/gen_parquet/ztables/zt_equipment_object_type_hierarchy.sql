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


create or replace temporary table zt_equipment_object_type_hierarchy as
select
    t."Object Type" as 'object_type',
    t."Object Type_1" as 'object_type_1',
    t."Equipment category" as 'equipment_category',
    t."Remarks" as 'remarks',
from read_xlsx(
    getvariable('source_xlsx'), 
    all_varchar=true) AS t;

copy 
    (select * from zt_equipment_object_type_hierarchy
    order by object_type, object_type_1, equipment_category)
to (getvariable('dest_parquet')) (format parquet, compression snappy);


