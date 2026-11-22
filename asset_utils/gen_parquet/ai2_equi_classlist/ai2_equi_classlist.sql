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

set variable inputs = ['ata_source_xlsx', 'attr_sets_source_xlsx', 'dest_dir'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));

from base_macros.assert_databases_are_loaded(['base_macros']);


create or replace temporary macro decode_data_type(dtype varchar) as 
case 
    when (dtype) = 'AIYEAR4'                        then 'integer'
    when dtype = 'BOOL'                             then 'boolean'
    when regexp_matches(dtype, 'CHAR[0-9]*')        then 'varchar'
    when regexp_matches(dtype, 'DATETIME[0-9]*')    then 'datetime'
    when regexp_matches(dtype, 'DECIMAL[0-9]*')     then 'decimal(18, 3)'
    when dtype = 'ENUM'                             then 'varchar'
    when regexp_matches(dtype, 'FLOAT[0-9]*')       then 'decimal(18, 3)'
    when regexp_matches(dtype, 'INT(EGER)?[0-9]*')  then 'integer'
    when regexp_matches(dtype, 'NUMERIC[0-9]*')     then 'decimal(18, 3)'
    when regexp_matches(dtype, 'VARCHAR[0-9]*')     then 'varchar'
    else 'varchar'
end;



create or replace temporary macro get_table_name(name varchar) as (
    replace(name, 'EQUIPMENT:', '').
        trim().
        regexp_replace('[^[:word:]]+', '_', 'g').
        regexp_replace('_$', '')
);


with cte1_ata_raw as (
    select 
        base_macros.nulled(trim(columns(t.*))),
    from read_xlsx(
            $ata_source_xlsx, 
            sheet = 'AssetTypesAttributes',
            all_varchar = true) as t
), cte2_ata_filtered as (
    select
        t.*
    from cte1_ata_raw t
    where t."Code" like 'EQPT%'
    and t."AssetTypeDeletionFlag" = '0'
    and t."AttributeNameDeletionFlag" = '0'
), cte3_asset_types_attributes as (
    select 
        t."Code" as class_name,
        t."Description" as class_description,
        trim(replace(t."Description", 'EQUIPMENT:', '')) as class_description2,
        t."AttributeSet" as attribute_set_name,
        t."Attribute Name" as attribute_name,
        t."Attribute Description" as attribute_description,
        if(t."Data Type Name" is null and t."LookupTypeId" is not null, 'ENUM', t."Data Type Name") as data_type,
        decode_data_type(data_type) as ddl_data_type,
        t."Lookup Type Name" as enum_name,
    from cte2_ata_filtered t
), cte4_attrs_raw as (
    select 
        base_macros.nulled(trim(columns(t.*))),
    from read_xlsx(
        $attr_sets_source_xlsx, 
        all_varchar = true, 
        sheet = 'Sheet1') t
), cte5_equi_attribute_sets_all as (
    select 
        t."Attribute Description" as class_name,
        t."Attribute Set" as attribute_set_name,
        t."Class Derivation" as class_derivation
    from cte4_attrs_raw t
    where t."Attribute Description" is not null
), cte6_filtered_attr_sets as (
    select 
        t.* 
    from cte5_equi_attribute_sets_all t
    where t.class_derivation in ('Equiclass', 'Equimixin') 
), cte7_ai2_equi_classes as (
    select 
        t1.*,
        t.class_derivation as class_derivation,
        case 
            when t.class_derivation = 'Equiclass' then get_table_name(t1.class_description)
            when t.class_derivation = 'Equimixin' then get_table_name(t1.attribute_set_name)
            else null 
        end as class_table_name,
    from cte6_filtered_attr_sets t
    join cte3_asset_types_attributes t1 
        on t1.class_description = t.class_name
        and t1.attribute_set_name = t.attribute_set_name
), cte8_output as materialized (
    -- Write to `dest_dir`, file_name is fixed...
    copy (
        select * from cte7_ai2_equi_classes
        order by class_name, attribute_set_name, attribute_name
    ) to ($dest_dir || '/ai2_equi_classlist.parquet') (format parquet, compression snappy)
)
select 'done' as ans;

select 'Wrote: ' || $dest_dir || '/ai2_equi_classlist.parquet' as result;

