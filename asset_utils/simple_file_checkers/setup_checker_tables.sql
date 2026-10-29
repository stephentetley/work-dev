--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--


create type checker_severity as enum ('error', 'warning');
create type checker_source as enum ('floc', 'equi');


create or replace table checker_results (
    source_file varchar not null,
    source_row integer not null,
    source_type checker_source not null,
    severity checker_severity not null, 
    floc_or_temp_id varchar not null,
    check_name varchar,
    message varchar,
);




