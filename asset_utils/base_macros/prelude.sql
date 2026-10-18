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