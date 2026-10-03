--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- 'Equi Name too long'
insert into checker_results
select 
    t.source_row,
    t.source_file,
    'equi'::checker_source as source_type, 
    'error'::checker_severity as severity, 
    t.temp_id as floc_or_temp_id,
    'Equi Name too long' as check_name,
    format('Equi Name "{}" is too long at {} characters', t.equi_name, length(t.equi_name)) as message,
from simple_equi_worklists t
where length(t.equi_name) > 40;
