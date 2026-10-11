--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The catalog `asset_facts_catalog.duckdb` is attached as `asset_facts`
-- the schema `asset_lib" as been created.
--


create or replace macro asset_lib.extract_process_group(common_name varchar) as table
select
    t.process_group_name
from asset_facts.ai2_process_group_process_names.process_group_names t
where common_name like '%/' || t.process_group_name  || '/%';

create or replace macro asset_lib.extract_process(common_name varchar) as table
select
    t.process_name
from asset_facts.ai2_process_group_process_names.process_names t
where common_name like '%/' || t.process_name  || '/%';

create or replace macro asset_lib.extract_process_group_process(common_name varchar) as table
select
    array_to_string([t.process_group_name, t1.process_name], '/') as process_group_process,
from 
    asset_lib.extract_process_group(common_name) t, 
    asset_lib.extract_process(common_name) t1;



create or replace macro asset_lib.extract_site_name(common_name varchar) as table
with cte1_pattern as (
    select
        regexp_escape('/' || t.process_group_process) as process_group_process_pattern,
    from asset_lib.extract_process_group_process(common_name) t
), cte2_use_regexp as (
    select
        regexp_extract(common_name, '^(.+)' || t.process_group_process_pattern, 1) as site_name,
    from cte1_pattern t
)
select * from cte2_use_regexp;

create or replace macro asset_lib.extract_equipment_type(common_name varchar) as table
select regexp_extract(common_name, '(.+)/EQ(UI)?P(MEN)?T: (.+)$', 4) as equipment_type;


