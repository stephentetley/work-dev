--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--


-- Preliminaries: 
-- Must have a sqlite database attached called `sqlite_db` (read-write)
-- and `asset_facts` and `asset_lib` DuckDB catalogs attached as read only
-- The variable `source_equiclass_attribs_parquet` is set in DuckDB (i.e. not an env var)
--
-- Run from DuckDB - no need for standalone SQLite to be installed 
-- 

.bail on

set variable inputs = ['source_equiclass_attribs_parquet'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));

from base_macros.assert_databases_are_loaded(['base_macros', 'sqlite_db']);


insert into sqlite_db.equi_create_classification by name
select
    t.batch_number,
    t.equi_id as equipment,
    t.class_name as class,
    t.characteristics as characteristics,
    t.char_value as char_value,
from read_parquet(getvariable('source_equiclass_attribs_parquet')) t
where t.batch_number is not null;


-- detach `sqlite_db` when done

