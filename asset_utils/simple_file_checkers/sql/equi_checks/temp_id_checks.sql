-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminary: 
-- The variable `equi_srcfile` is set in DuckDb (i.e. not an env var)
--

-- 'Temp ID not ordered'
insert into checker_results by name
with cte1_with_prev as (
    select 
        t.source_row,
        t.temp_id,
        lag(t.temp_id, 1) over (order by source_row) as prev_temp_id
    from simple_equi_worklist t
), cte2_find_violations as (
    select 
        * 
    from cte1_with_prev
    where temp_id <= prev_temp_id
)
select 
    t.source_row,
    getvariable('equi_srcfile') as source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.temp_id as floc_or_temp_id,
    'Temp ID not ordered' as check_name,
    format('The Temp ID {} is not greater than the previous line {}', t.temp_id, t.prev_temp_id) as message,
from cte2_find_violations t;


