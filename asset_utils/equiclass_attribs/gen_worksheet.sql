    --
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--


-- Preliminaries: 
-- `asset_facts_catalog` is attached as `asset_facts` (read_only)
-- `asset_lib_catalog` is attached as `asset_lib` (read_only)
-- The variable `source_simple_equi_parquet` is set in DuckDb (i.e. not an env var)
-- The variable `dest_equiclass_attribs_xlsx` is set in DuckDb (i.e. not an env var)

-- Generates an "equiclass_attribs" file with a row of name-value pairs for each 
-- equipment item. The user fills in the values where they can.


.bail on
load excel;

with cte1_variables as (
select 
    ifnull(getvariable('source_simple_equi_parquet'), error('Must set variable "source_simple_equi_parquet"')) as source_simple_equi_parquet,
    ifnull(getvariable('dest_equiclass_attribs_xlsx'), error('Must set variable "dest_equiclass_attribs_xlsx"')) as dest_equiclass_attribs_xlsx,
)
unpivot cte1_variables
on columns(*)
into name variable value value;


with cte1_databases as (
select 
    if(exists (from duckdb_databases() where database_name = 'asset_facts'), 
        true, 
        error('Must attach database "asset_facts"')) as asset_facts,
    if(exists (from duckdb_databases() where database_name = 'asset_lib'), 
        true, 
        error('Must attach database "asset_lib"')) as asset_lib,
)
unpivot cte1_databases
on columns(*)
into name database value loaded;

create or replace temporary view vw_simple_equi_source as
select * from read_parquet(getvariable('source_simple_equi_parquet'));

create or replace temporary table class_attrs_plus_blank_values as
with cte1_chars as (
    select 
        t.temp_id,
        t1.char_name,
    from vw_simple_equi_source t
    join asset_facts.s4_classlists.equi_classlist t1 on t1.class_name = t.equi_class
    where t1.char_name not in ('LOCATION_ON_SITE', 'UNICLASS_CODE', 'UNICLASS_DESC')
    order by temp_id, char_name
), cte2_with_attr_indices as (
    select 
        t.*,
        row_number() over (partition by temp_id order by char_name) as char_ix,
        format('{:03d}_Attribute', char_ix) as column_name,
    from cte1_chars t
), cte3_with_value_indices as (
    select 
        t.temp_id,
        null as char_name,
        row_number() over (partition by temp_id order by char_name) as char_ix,
        format('{:03d}_Value', char_ix) as column_name,
    from cte1_chars t
), cte4_union_stacked_attr_value as (
    select * exclude (char_ix) from cte2_with_attr_indices 
    union by name
    select * exclude (char_ix) from cte3_with_value_indices 
)
pivot cte4_union_stacked_attr_value
on column_name  
using first(char_name);

create or replace temporary view vw_classequi_attribute_values as
select 
    t.temp_id as "Equipment", 
    t.equi_name as "Description of technical object",
    t.functional_location as "Functional Location",
    t.equi_class as "Class",
    t.ai2_pli_number as "PLI Num",
    t1.* exclude (temp_id),
from vw_simple_equi_source t
join class_attrs_plus_blank_values t1 on t1.temp_id = t.temp_id;


-- Don't fix the output table name, user defined...
copy (
    select * from vw_classequi_attribute_values order by "Class", "Functional Location"
) to (getvariable('dest_equiclass_attribs_xlsx')) (format xlsx, header true, sheet 'EquiAttribs');

select 'Wrote: ' || getvariable('dest_equiclass_attribs_xlsx') as result;
