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