--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminary: 
-- The variable `floc_srcfile` is set in DuckDb (i.e. not an env var)
--

-- 'Floc Name too long'
insert into checker_results by name
select 
    t.source_row,
    getvariable('floc_srcfile') as source_file,
    'floc'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.functional_location    as floc_or_temp_id,
    'Floc Name too long' as check_name,
    format('Floc Name "{}" is too long at {} characters', t.floc_name, length(t.floc_name)) as message,
from simple_floc_worklist t
where length(t.floc_name) > 40;

-- malformed floc

create or replace temporary macro check_site_of_floc(flocname varchar) as 
    regexp_matches(flocname, '^\p{Lu}{5}') 
        or regexp_matches(flocname, '^\p{Lu}{4}\d')
        or regexp_matches(flocname, '^\p{Lu}{3}\d{2}');

create or replace temporary macro check_floc_shape(flocname varchar, category integer) as 
    case check_site_of_floc(flocname)
        when true then
            case category
                when 1 then length(flocname) == 5
                when 2 then regexp_matches(flocname, '^\S{5}-\p{Lu}{3}$')
                when 3 then regexp_matches(flocname, '^\S{5}-\p{Lu}{3}-\p{Lu}{3}$')
                when 4 then regexp_matches(flocname, '^\S{5}-\p{Lu}{3}-\p{Lu}{3}-\p{Lu}{3}$')
                when 5 then regexp_matches(flocname, '^\S{5}-\p{Lu}{3}-\p{Lu}{3}-\p{Lu}{3}-SYS\d{2}$')
                when 6 then regexp_matches(flocname, '^\S{5}-\p{Lu}{3}-\p{Lu}{3}-\p{Lu}{3}-SYS\d{2}-\p{Lu}{3}\d{2}$')
                else false
            end
        else false
    end;

-- malformed floc
insert into checker_results by name
select 
    t.source_row,
    getvariable('floc_srcfile') as source_file,
    'floc'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.functional_location as floc_or_temp_id,
    'Malformed Floc' as check_name,
    format('Function location "{}" is malformed for level level {}', t.functional_location, t.floc_category) as message,
from simple_floc_worklist t
where check_floc_shape(t.functional_location, t.floc_category) > 40;



-- 'Missing or Invalid Category'
insert into checker_results by name
select 
    t.source_row,
    getvariable('floc_srcfile') as source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.functional_location as floc_or_temp_id,
    'Missing or Invalid Category' as check_name,
    format('Installation Allowed checked on floc "{}" which is category {}', 
            t.functional_location, t.floc_category) as message,
from simple_floc_worklist t
where t.floc_category is null or t.floc_category < 1 or t.floc_category > 6;


-- 'Incorrect Installation Allowed'
insert into checker_results by name
select 
    t.source_row,
    getvariable('floc_srcfile') as source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.functional_location as floc_or_temp_id,
    'Incorrect Installation Allowed' as check_name,
    format('Installation Allowed checked on floc "{}" which is category {}', 
            t.functional_location, t.floc_category) as message,
from simple_floc_worklist t
where t.installation_allowed and t.floc_category < 5;

-- 'Missing Installation Allowed'
insert into checker_results by name
select 
    t.source_row,
    getvariable('floc_srcfile') as source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.functional_location as floc_or_temp_id,
    'Missing Installation Allowed' as check_name,
    format('Installation Allowed missing on floc "{}" which is category {}', 
            t.functional_location, t.floc_category) as message,
from simple_floc_worklist t
where t.installation_allowed == false and t.floc_category > 5;

-- 'Unrecognized Floc Type'
insert into checker_results by name
with cte1_levels_1_4 as (
    select * from simple_floc_worklist where floc_category < 5
)
select 
    t.source_row,
    getvariable('floc_srcfile') as source_file,
    'floc'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.functional_location as floc_or_temp_id,
    'Unrecognized Floc Type' as check_name,
    format('Unrecognized Floc type "{}"', t.floc_type) as message,
from cte1_levels_1_4 t
anti join asset_lake.ztables.flobjl t1 
    on (t1.structure_indicator == t.str_indicator and t1.object_type_1 == t.floc_type);


-- 'Parent Child Type Error'
-- Only checks when parent flocs in the worklist!
insert into checker_results by name
with cte1_floc_and_parent as (
    select 
        t.functional_location,
        max(t1.functional_location) as parent,
    from simple_floc_worklist t
    join simple_floc_worklist t1 on starts_with(t.functional_location, t1.functional_location) and t1.functional_location < t.functional_location
    group by all
), cte2_add_objtypes as (
    select 
        t1.source_row,
        t.functional_location,
        t1.str_indicator,
        t1.floc_type,
        t.parent,
        t2.floc_type as parent_type
    from cte1_floc_and_parent t
    join simple_floc_worklist t1 on t1.functional_location = t.functional_location
    join simple_floc_worklist t2 on t2.functional_location = t.parent
)
select 
    t.source_row,
    getvariable('floc_srcfile') as source_file,
    'floc'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.functional_location as floc_or_temp_id,
    'Parent-Child Type Error' as check_name,
    format('Floc type "{}" cannot be a child of the parent type "{}"', t.floc_type, t.parent_type) as message,
from cte2_add_objtypes t
anti join asset_lake.ztables.flobjl t1 
    on (t1.structure_indicator == t.str_indicator and t1.object_type == t.parent_type and t1.object_type_1 == t.floc_type);

-- 'Duplicate Functional Locations'
insert into checker_results by name
with cte1_floc_occurs as (
    select 
        t.functional_location,
        list(t.source_row) as row_nums
    from simple_floc_worklist t
    group by all
), cte2_floc_duplicates as (
    select 
        t.*,
    from cte1_floc_occurs t
    where list_count(t.row_nums) > 1
)
select 
    list_min(t.row_nums) as source_row,
    getvariable('floc_srcfile') as source_file,
    'floc'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.functional_location as floc_or_temp_id,
    'Duplicate Functional Locations' as check_name,
    format('Floc "{}" is duplicated, see rows {}', t.functional_location, t.row_nums) as message,
from cte2_floc_duplicates t;


-- 'Missing Mandatory Data'
create or replace temporary macro floc_missing_mandatory(colname varchar, longname varchar) as table 
from query(
    format('select t.source_row, t.functional_location, ''{}'' as missing1, from simple_floc_worklist t where t.{} is null;', longname, colname)
);


-- 'Missing Mandatory Data'
insert into checker_results by name
with cte1_missing1 as (
    select * from floc_missing_mandatory('batch_number', 'Batch Number')
    union by name
    select * from floc_missing_mandatory('functional_location', 'Functional Location')
    union by name
    select * from floc_missing_mandatory('floc_name', 'Floc Name')
    union by name
    select * from floc_missing_mandatory('floc_category', 'Category')
    union by name
    select * from floc_missing_mandatory('str_indicator', 'Str Indicator')
    union by name
    select * from floc_missing_mandatory('floc_type', 'Floc Type')
    union by name
    select * from floc_missing_mandatory('maint_plant', 'Maint Plant')
    union by name
    select * from floc_missing_mandatory('cost_center', 'Cost Center')
    union by name
    select * from floc_missing_mandatory('main_work_center', 'Main Work Center')
    union by name
    select * from floc_missing_mandatory('user_status', 'User Status')
    union by name
    select * from floc_missing_mandatory('startup_date', 'Startup Date')
), cte2_grouped as (
    select
        t.source_row, 
        t.functional_location,
        string_agg(t.missing1, ', ' order by t.missing1 desc) as missing,
    from cte1_missing1 t
    group by all
)
select 
    t.source_row,
    getvariable('floc_srcfile') as source_file,
    'floc'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.functional_location as floc_or_temp_id,
    'Missing Mandatory Data' as check_name,
    format('Floc "{}" is missing the mandatory data {}', t.functional_location, t.missing) as message,
from cte2_grouped t;


