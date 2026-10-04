--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminary: 
-- The variable `equi_srcfile` is set in DuckDb (i.e. not an env var)
-- AssetLake must be attached for ztables

-- 'Equi Name too long'
insert into checker_results by name
select 
    t.source_row,
    getvariable('equi_srcfile') as source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.temp_id as floc_or_temp_id,
    'Equi Name too long' as check_name,
    format('Equi Name "{}" is too long at {} characters', t.equi_name, length(t.equi_name)) as message,
from simple_equi_worklist t
where length(t.equi_name) > 40;

-- 'Bad Manuf Model combination'
insert into checker_results by name
select 
    t.source_row,
    getvariable('equi_srcfile') as source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.temp_id as floc_or_temp_id,
    'Bad Manuf-Model Combination' as check_name,
    format('Invalid manfacturer "{}" model "{}" combination', t.manufacturer, t.model_number) as message,
from simple_equi_worklist t
anti join asset_lake.ztables.manuf t1 on (t1.manufacturer == t.manufacturer and t1.model == t.model_number);

-- 'Bad Objtype Manuf Combination'
insert into checker_results by name
select 
    t.source_row,
    getvariable('equi_srcfile') as source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.temp_id as floc_or_temp_id,
    'Bad Objtype-Manuf Combination' as check_name,
    format('No ztable rule for "{}" manufacturer "{}" combination', coalesce(t.equi_type, 'null'), coalesce(t.manufacturer, 'null')) as message,
from simple_equi_worklist t
anti join asset_lake.ztables.objtype_manuf t1 on (t1.object_type == t.equi_type and t1.manufacturer == t.manufacturer);
