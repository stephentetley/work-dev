--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The schema `base_macros" exists.
--

create or replace macro base_macros.nulled(str varchar) as 
    if(str == '' or upper(str) == 'NULL', null, str);

create or replace macro base_macros.unnulled(str varchar) as
    if(str is null or upper(str) == 'NULL', '', str);


create or replace macro base_macros.assert_databases_are_loaded(names varchar[]) as table (
with cte1_unested as (
    select unnest(names) as database_name
)
select 
    t.database_name, 
    if(t1.path is not null, true, error(format('The database "{}" is not loaded', t.database_name))) as loaded,
    from cte1_unested t
    left join duckdb_databases() t1 on t1.database_name = t.database_name
);

create or replace macro base_macros.snake_case(str varchar) as (
with cte1_common as (
    select regexp_extract_all(str, '\S\p{Lu}') as tokens,
), cte2_worker as (
    select
        list_reduce(tokens, lambda str, tk: replace(str, tk, tk[1] || '_' || tk[2]),  str) as answer
    from cte1_common
)
select lower(answer) from cte2_worker);

create or replace macro base_macros.kebab_case(str varchar) as (
with cte1_common as (
    select regexp_extract_all(str, '\S\p{Lu}') as tokens,
), cte2_worker as (
    select
        list_reduce(tokens, lambda str, tk: replace(str, tk, tk[1] || '-' || tk[2]),  str) as answer
    from cte1_common
)
select lower(answer) from cte2_worker);

create or replace macro base_macros.pascal_case(str varchar) as (
with cte1_worker as (
    select
        regexp_replace(str, '[_-]', ' ', 'g') as normed,
        regexp_extract_all(normed, '[\s_-]+\p{L}') as tokens,
        list_reduce(tokens, lambda str, tk: replace(str, tk, upper(trim(tk))), normed) as all_but_first,
        upper(all_but_first[1]) || all_but_first[2:] as answer
)
select answer from cte1_worker);

create or replace macro base_macros.camel_case(str varchar) as (
with cte1_worker as (
    select
        regexp_replace(str, '[_-]', ' ', 'g') as normed,
        regexp_extract_all(normed, '[\s_-]+\p{L}') as tokens,
        list_reduce(tokens, lambda str, tk: replace(str, tk, upper(trim(tk))), normed) as all_but_first,
        lower(all_but_first[1]) || all_but_first[2:] as answer
)
select answer from cte1_worker);


