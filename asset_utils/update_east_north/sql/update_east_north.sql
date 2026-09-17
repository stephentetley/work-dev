create schema if not exists eastnorth_landing;




create or replace table eastnorth_landing.selectors as
with cte1_raw as (
    select 
        t.*
    from read_xlsx(
        getvariable('floc_selectors'),
        all_varchar=true, 
        sheet='Sheet1'
    ) as t
), cte2_typed as (
    select
        try_cast(t."Priority" as integer) as priority,
        t."Pattern" as pattern,
        try_cast(t."Easting" as integer) as easting,
        try_cast(t."Northing" as integer) as northing,
    from cte1_raw t
) 
select * from cte2_typed;

create or replace table eastnorth_landing.floc_worklist as
select 
    t.*
from read_xlsx(
    getvariable('update_en_floc_worklist'),
    all_varchar=true, 
    sheet='Sheet1'
) as t;

create or replace table eastnorth_landing.equi_worklist as
select 
    t.*
from read_xlsx(
    getvariable('update_en_equi_worklist'),
    all_varchar=true, 
    sheet='Sheet1'
) as t;


-- Flocs
insert into sqlite_db.floc_change_classification by name
with cte1_best_match as (
    select 
        t."Functional Location" as floc,
        max(t1.priority) as priority,
    from eastnorth_landing.floc_worklist t
    join eastnorth_landing.selectors t1 on t."Functional Location" LIKE t1.pattern
    group by t."Functional Location"
), cte2_joined as (
    select 
        t.floc,
        t.priority,
        t1.pattern,
        t1.easting,
        t1.northing,
    from cte1_best_match t
    join eastnorth_landing.selectors t1 on t1.priority = t.priority
), cte_easting as (
    select
        1 as batch_number,
        t.floc as functional_location,
        'EAST_NORTH' as class,
        'EASTING' as characteristics,
        try_cast(t.easting as varchar) char_value,
    from cte2_joined t
), cte_northing as (
    select
        1 as batch_number,
        t.floc as functional_location,
        'EAST_NORTH' as class,
        'NORTHING' as characteristics,
        try_cast(t.northing as varchar) as char_value,
    from cte2_joined t
)
(select * from cte_easting
union by name
select * from cte_northing
)
order by functional_location, class, characteristics
;

-- Equipment
insert into sqlite_db.equi_change_classification by name
with cte1_best_match as (
    select 
        t."Functional Location" as floc,
        max(t1.priority) as priority,
    from eastnorth_landing.equi_worklist t
    join eastnorth_landing.selectors t1 on t."Functional Location" LIKE t1.pattern
    group by t."Functional Location"
), cte2_joined as (
    select 
        t."Equipment" as equi,
        t1.priority,
        t2.pattern,
        t2.easting,
        t2.northing,
    from eastnorth_landing.equi_worklist t
    join cte1_best_match t1 on t1.floc = t."Functional Location"
    join eastnorth_landing.selectors t2 on t2.priority = t1.priority
), cte_easting as (
    select
        1 as batch_number,
        t.equi as equipment,
        'EAST_NORTH' as class,
        'EASTING' as characteristics,
        try_cast(t.easting as varchar) char_value,
    from cte2_joined t
), cte_northing as (
    select
        1 as batch_number,
        t.equi as equipment,
        'EAST_NORTH' as class,
        'NORTHING' as characteristics,
        try_cast(t.northing as varchar) as char_value,
    from cte2_joined t
)
(select * from cte_easting
union by name
select * from cte_northing
)
order by equipment, class, characteristics
;
