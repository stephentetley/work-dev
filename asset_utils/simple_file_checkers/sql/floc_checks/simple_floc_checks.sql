--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminary: 
-- The variable `floc_srcfile` is set in DuckDb (i.e. not an env var)
--

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

