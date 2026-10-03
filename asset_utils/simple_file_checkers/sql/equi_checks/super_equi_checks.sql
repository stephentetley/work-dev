--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--



-- 'Super equi not defined'
insert into checker_results
with cte1_find_superlines as (
    select 
        t.source_row,
        t.source_file,
        t.temp_id,
        t.super_equi_id
    from simple_equi_worklists t
    where regexp_matches(t.super_equi_id, '^\$\d+$')
), cte2_missing_parent as (
    select 
        t.source_row,
        t.source_file,
        t.temp_id,
        t.super_equi_id,
    from cte1_find_superlines t
    where not exists (from simple_equi_worklists t1 
                    where t1.temp_id = t.super_equi_id 
                    and t1.source_file = t.source_file)
) 
select 
    t.source_row,
    t.source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.temp_id as floc_or_temp_id,
    'Super equi not defined' as check_name,
    format('Super equi {} is not found for equipment {}', t.super_equi_id, t.temp_id) as message,
from cte2_missing_parent t;


-- 'Child before Super', assumes proper ordering
insert into checker_results
with cte1_find_superlines as (
    select 
        t.source_row,
        t.source_file,
        t.temp_id,
        t.super_equi_id
    from simple_equi_worklists t
    where regexp_matches(t.super_equi_id, '^\$\d+$')
), cte2_child_before_parent as (
    select 
        t.source_row,
        t.source_file,
        t.temp_id,
        t.super_equi_id,
    from cte1_find_superlines t
    where t.temp_id < t.super_equi_id
) 
select 
    t.source_row,
    t.source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.temp_id as floc_or_temp_id,
    'Child before Super' as check_name,
    format('Child equipment {} is defined after super equi {}', t.temp_id, t.super_equi_id) as message,
from cte2_child_before_parent t;


-- 'Child equal Super'
insert into checker_results
with cte1_find_superlines as (
    select 
        t.source_row,
        t.source_file,
        t.temp_id,
        t.super_equi_id
    from simple_equi_worklists t
    where regexp_matches(t.super_equi_id, '^\$\d+$') and t.temp_id == t.super_equi_id
) 
select 
    t.source_row,
    t.source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.temp_id as floc_or_temp_id,
    'Child equals Super' as check_name,
    format('Child equipment {} is same as super equi {}', t.temp_id, t.super_equi_id) as message,
from cte1_find_superlines t;



