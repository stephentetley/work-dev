--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The schema `asset_lib" as been created.
--

create or replace macro asset_lib.same_site_code(floc1 varchar, floc2 varchar) as
floc1[1:5] = floc2[1:5];

create or replace macro asset_lib.same_function_code(floc1 varchar, floc2 varchar) as
floc1[7:9] = floc2[7:9];

create or replace macro asset_lib.same_process_group_code(floc1 varchar, floc2 varchar) as
floc1[11:13] = floc2[11:13];

create or replace macro asset_lib.same_process_code(floc1 varchar, floc2 varchar) as
floc1[15:17] = floc2[15:17];


create or replace macro asset_lib.common_site(floc1 varchar, floc2 varchar) as
floc1[1:5] = floc2[1:5];

create or replace macro asset_lib.common_function(floc1 varchar, floc2 varchar) as
floc1[1:9] = floc2[1:9];

create or replace macro asset_lib.common_process_group(floc1 varchar, floc2 varchar) as
floc1[1:13] = floc2[1:13];

create or replace macro asset_lib.common_process(floc1 varchar, floc2 varchar) as
floc1[1:17] = floc2[1:17];

create or replace macro asset_lib.common_system(floc1 varchar, floc2 varchar) as
floc1[1:23] = floc2[1:23];

create or replace macro asset_lib.common_subsystem(floc1 varchar, floc2 varchar) as
floc1[1:29] = floc2[1:29];

