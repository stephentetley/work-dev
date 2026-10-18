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

create or replace temporary table table1 as
with cte1_raw as (
    select 
        base_macros.nulled(trim(columns(t.*))),
    from read_csv(
        getvariable('source_tsv'),
        delim = '\t',
        header = true,
        all_varchar = true,
        filename = true
    ) t
), cte2_refine_columns as (
    select 
        t.filename,
        try_cast(t."No." as integer) as point_number,
        t."Pt name" as point_name,
        t."Ty" as point_ty,
        t."D" as point_d,
        t."Point comment" as point_comment,
        t."Value" as point_value,
        t."AC" as ac,
        t."Al Rt" as al_rt,
        t."Fa" as fa,
        t."Scan" as scan,
        t."Fn" as fn,
        t."Record" as record,
    from cte1_raw t
)
select * from cte2_refine_columns;

-- Don't fix the output table name, expect multiple runs...
copy (
    select * from table1 order by filename, point_number
) to (getvariable('dest_path')) (format parquet, compression snappy);

select 'Wrote: ' || getvariable('dest_path') as result;

