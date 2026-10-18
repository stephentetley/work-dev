    --
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--


-- Preliminaries: 
-- `base_macros_catalog` is attached as `base_macros` (read_only)
-- `asset_facts_catalog` is attached as `asset_facts` (read_only)
-- `asset_lib_catalog` is attached as `asset_lib` (read_only)
-- The variable `source_simple_equi_parquet` is set in DuckDb (i.e. not an env var)
-- The variable `dest_equiclass_attribs_xlsx` is set in DuckDb (i.e. not an env var)

-- Generates an "equiclass_attribs" file with a row of name-value pairs for each 
-- equipment item. The user fills in the values where they can.


.bail on
load excel;

set variable inputs = ['source_simple_equi_parquet', 'dest_equiclass_attribs_xlsx'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));

from base_macros.assert_databases_are_loaded(['base_macros', 'asset_facts', 'asset_lib']);

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
    t.batch_number as "Batch Number",
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
