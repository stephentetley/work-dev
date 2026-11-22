--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- `base_macros_catalog` is attached as `base_macros` (read_only)
-- The variables `ata_source_xlsx`, `attr_sets_source_xlsx' and `dest_dir` are set in 
-- DuckDb (i.e. not env vars)
--

.bail on
load excel;

-- set variable file_name = 'netwtl.xlsx';
-- set variable sheet_name = 'Telemetry System Network Node';


set variable inputs = ['file_name', 'sheet_name'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));


create or replace macro get_equiclass_name(class_desc varchar) as (
select 
    any_value(class_name)
from asset_facts.s4_classlists.equi_classlist 
where class_description = class_desc 
group by all);

create or replace macro get_equiclass_attr_descriptions(class_desc varchar) as (
with cte1_names as (
    select 
        char_description
    from asset_facts.s4_classlists.equi_classlist 
    where class_description = class_desc 
    order by char_ix
), cte2_agg as (
    select array_agg(char_description) as agg from cte1_names t
) 
select any_value(t.agg) from cte2_agg t);


set variable attrs = get_equiclass_attr_descriptions($sheet_name);

with cte1_raw as (
    select 
        base_macros.nulled(trim(columns(t.*))),
    from read_xlsx(
        $file_name,
        all_varchar = true, 
        sheet = $sheet_name
    ) as t
), cte2_tidied as ( 
    select 
        t."Temp ID" as temp_id,
        t."Equi Class" as equiclass,
        columns(lambda c: c in $attrs),
    from cte1_raw t
), cte3_unpivoted as (
    unpivot cte2_tidied
    on columns(* exclude (temp_id, equiclass))
    into name attr_name value attr_value
), cte4_rewrite_attr_names as (
    select 
        t.temp_id,
        t.equiclass,
        t1.char_name as attr_name,
        t.attr_value,
    from cte3_unpivoted t
    join asset_facts.s4_classlists.equi_classlist t1 on t1.char_description = t.attr_name and t1.class_name = $class_name
)
select * from cte4_rewrite_attr_names;



