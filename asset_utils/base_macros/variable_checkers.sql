--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The schema `base_macros" exists.
--

create or replace macro base_macros.get_variables_table(names varchar[]) as table (
with cte1_common as (
    select unnest(names) as var_name
)
select 
    t.var_name, 
    t1.value as var_value,
    from cte1_common t
    left join duckdb_variables() t1 on t1.name = t.var_name
);

create or replace macro base_macros.assert_variables_are_set(names varchar[]) as table (
select 
     t.var_name as variable,
     ifnull(t.var_value, error(format('Must set variable "{}"', t.var_name))) as value,
from base_macros.get_variables_table(names) t
);

create or replace macro base_macros.assert_variables_are_distinct(names varchar[]) as table (
with cte1_defs as (
    select 
        t.var_value as value,
        list(t.var_name order by t.var_name) as defs,
    from base_macros.get_variables_table(names) t
    group by t.var_value
), cte2_report as (
    select 
        if(length(t.defs) == 1, t.defs[1], error(format('The variables [{}] point to the same file "{}" this likely means the input will be overwritten by the output', array_to_string(t.defs, ', '), t.value))) as variable,
        t.value,
    from cte1_defs t
)
select * from cte2_report
);


create or replace macro base_macros.assert_env_vars_are_set(names varchar[]) as table (
with cte1_common as (
    select unnest(names) as name
), cte2_env_lookups as (
    select
        name as var_name,
        getenv(name) as var_value,
    from cte1_common t
), cte3_check_envvars as (
    select
        t.var_name as variable,
        if(t.var_value is null or t.var_value == '', error(format('Must set env var "{}"', t.var_name)), t.var_value) as value,
    from cte2_env_lookups t
)
select * from cte3_check_envvars);

