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
insert into checker_results
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
insert into checker_results
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

