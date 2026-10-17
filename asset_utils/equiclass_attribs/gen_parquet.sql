--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `source_equiclass_attribs_xlsx` and `dest_equi_characterics_parquet` are set in 
-- DuckDB (i.e. not env vars)
--


.bail on
load excel;

with cte1_variables as (
select 
    ifnull(getvariable('source_equiclass_attribs_xlsx'), error('Must set variable "source_equiclass_attribs_xlsx"')) as source_equiclass_attribs_xlsx,
    ifnull(getvariable('dest_equi_characterics_parquet'), error('Must set variable "dest_equi_characterics_parquet"')) as dest_equi_characterics_parquet,
)
unpivot cte1_variables
on columns(*)
into name variable value value;



create or replace temporary macro unnulled(str varchar) as
if(str is null, '', str);


-- Note - us unnnulled to get empty string - null is incompatible with unpivot
create or replace temporary table table1 as
with cte1_raw as (
    select 
        unnulled(trim(columns(t.*))),
    from read_xlsx(
        getvariable('source_equiclass_attribs_xlsx'), 
        sheet = 'EquiAttribs', 
        all_varchar = true) t
), cte2_unpivot as (
    unpivot cte1_raw
    on columns(lambda c: c like '%_Attribute' or c like '%_Value')
    into
        name cname
        value cvalue
), cte3_classified as (
    select 
        t."Equipment" as equi_id,
        t."Class" as class_name,
        case 
            when t.cname like '%_Attribute' then 'attr' 
            when t.cname like '%_Value' then 'value'
            else null
        end as row_type,
        if (row_type = 'attr', t.cvalue, null) as attr_name,
        if (row_type = 'value', t.cvalue, null) as attr_value,
        try_cast(regexp_extract(t.cname, '^(\d+)_\p{L}+$', 1) as integer) as index,
    from cte2_unpivot t
    where t.cvalue is not null
), cte4_columns_filled_out as (
    select 
        t.equi_id,
        t.class_name,
        t1.attr_name as characteristics,
        t.attr_value as char_value
    from cte3_classified t
    join cte3_classified t1 
        on t1.equi_id = t.equi_id
        and t1.index = t.index
        and t1.row_type = 'attr'
    where t.attr_value is not null
)
select * from cte4_columns_filled_out;  



-- Don't fix the output table name, user defined...
-- Generate parquet first so we can run checkers
copy (
    select * from table1 order by class_name, equi_id, characteristics
) to (getvariable('dest_equi_characterics_parquet')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_equi_characterics_parquet') as result;

