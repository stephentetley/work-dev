--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- `base_macros_catalog` is attached as `base_macros` (read_only)
-- The variables `source_tsv` and `dest_path` are set in 
-- DuckDb (i.e. not env vars)
--

.bail on

set variable inputs = ['source_tsv', 'dest_path'];
from base_macros.assert_variables_are_set(getvariable('inputs'));
from base_macros.assert_variables_are_distinct(getvariable('inputs'));

from base_macros.assert_databases_are_loaded(['base_macros']);


with cte1_raw as (
    select 
        row_number() over () as row_ix,
        base_macros.nulled(trim(columns(t.*))),
    from read_csv(
        getvariable('source_tsv'),
        delim = '\t',
        header = true,
        all_varchar = true,
        filename = true
    ) t
), cte2_add_missing_fields as (
    select * from cte1_raw
    union by name
    (select 
        null::varchar as "Updated         Method",
        null::varchar as "Alarm status",
        null::varchar as "Fail",
        null::varchar as "Scan",
        null::varchar as "OD name",
        null::varchar as "OD comment",
        null::varchar as "Function",
        null::varchar as "Function comment",
        null::varchar as "Ctrl pic  Alarm pic",
     limit 0)
), cte3_decoded as (
    select 
        t.filename,
        row_number() over (partition by t.filename order by t.row_ix) as row_ix,
        regexp_extract(t."OS\Point name", '^(\S+)\s+\\(\S+)$', 1) as outstation,
        regexp_extract(t."OS\Point name", '^(\S+)\s+\\(\S+)$', 2) as point_name,
        regexp_extract(t."Der. Typ. No", '^(\S+)\s+(\S+)\s+(\d+)$', 1) as derivation,
        regexp_extract(t."Der. Typ. No", '^(\S+)\s+(\S+)\s+(\d+)$', 2) as point_type,
        try_cast(regexp_extract(t."Der. Typ. No", '^(\S+)\s+(\S+)\s+(\d+)$', 3) as integer) as point_number,
        t."Value" as value,
        try(strptime(regexp_extract(t."Updated         Method", '^(.+)\s+(\S+)$', 1), '%H:%M %d-%b-%y')) as updated,
        regexp_extract(t."Updated         Method", '^(.+)\s+(\S+)$', 2) as method,
        t."Alarm status" as alarm_status,
        t."Fail" as fail,
        t."Scan" as scan,
        t."OD name" as od_name,
        t."OD comment" as od_comment,
        t."Function" as od_function,
        t."Function comment" as od_function_comment,
        regexp_extract(t."Ctrl pic  Alarm pic", '^(\S+)', 1) as control_pic,
        regexp_extract(t."Ctrl pic  Alarm pic", '^(\S+)\s+(\S+)$', 2) as alarm_pic,
    from cte2_add_missing_fields t
), cte4_export as materialized (
    -- Don't fix the output table name, expect multiple runs...
    copy (
        select * from cte3_decoded order by filename, row_ix
    ) to (getvariable('dest_path')) (format parquet, compression snappy)
)
select 'done' as ans;

select 'Wrote: ' || $dest_path as result;

