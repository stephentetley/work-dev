
--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The variables `user_annos_xlsx` and `_____` are set in 
-- DuckDb (i.e. not env vars)

load excel;

create or replace temporary macro nulled(str varchar) as 
    if(str == '' or upper(str) == 'NULL', null, str);


insert into input.user_annos by name
with cte1_raw as (
    select 
        row_number() over () as row_ix,
        nulled(trim(columns(*))),
    from read_xlsx(
            getvariable('user_annos_xlsx'), 
            sheet='UserAnnos',
            all_varchar=true) as t
), cte2_named_columns as (
    select 
        t."PLI Number" as pli_num,
        t."Process Group / Process" as process_group_process,
        t."Equipment Name" as equipment_name,
        t."Equipment Type" as equipment_type,
        try_cast(t."System Index" as integer) as system_index,
        t."System Description Fstring" as system_description_fstring,
        t."System Class" as system_class,
        t."System Type Description" as system_type_description,
        try_cast(t."Subsystem Index" as integer) as subsys_index,
        t."Subsystem Description Fstring" as subsys_description_fstring,
    from cte1_raw t
)
select * from cte2_named_columns;
