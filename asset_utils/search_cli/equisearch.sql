-- asset_facts is attached
load fts;

create or replace table equitype as
select 
    t.class_name[1:4] as objtype,
    t.class_name as class, 
    t.class_description as description,
    concat_ws(' ', lower(objtype), lower(class), lower(t.class_description)) as text_content,
from asset_facts.s4_classlists.equi_classlist t
where t.char_name = 'LOCATION_ON_SITE'
order by class;


create or replace table equipment as
select 
    t.equi_id,
    t.equi_name,
    t.standard_class as class,
    t.functional_location,
    t.tech_ident_num,
    t1.text_content as type_long_text,
    concat_ws(' ', t.equi_type, t.standard_class, t.equi_name, t.tech_ident_num).lower() as description_long_text,
from read_parquet('minimal_equis.parquet') t
join equitype t1 on t1.class = t.standard_class;

pragma create_fts_index(
    'equipment', 'equi_id', 'type_long_text', 'description_long_text', overwrite = 1
);

create or replace macro search_equitype(anystr varchar) as table
with cte1_raw_score as (
    select
        fts_main_equipment.match_bm25(
            equi_id, 
            anystr, 
            fields := 'type_long_text',
            conjunctive := false) as score,
        equi_id,
    from equipment
)
select 
    if(anystr is null, null, coalesce(score, 0.0)) as score,
    equi_id,
from cte1_raw_score;

create or replace macro search_equidesc(anystr varchar) as table
select
    fts_main_equipment.match_bm25(
        equi_id, 
        anystr, 
        fields := 'description_long_text',
        conjunctive := false) as score,
    equi_id,
from equipment
where score is not null;


-- TODO - work on a list
create or replace macro exact_substring(sub varchar) as table
select
    2.0 as score,
    equi_id,
from equipment
where contains(description_long_text, lower(sub))
union by name
select
    0.0 as score,
    equi_id,
from equipment
where not contains(description_long_text, lower(sub));

create or replace macro search_equipment(equidesc varchar, equitype varchar := null, keyword varchar := null) as table
with cte1_unions as (
    -- must be a union not a join
    select * from search_equidesc(equidesc) where score is not null
    union by name
    select * from search_equitype(equitype) where score is not null
    union by name
    select * from exact_substring(keyword) where score is not null
), cte2_grouped as (
    select 
        product(score) as score,
        equi_id,
        -- first(class) as class,
        -- first(equi_name) as equi_name,
        -- first(tech_ident_num) as tech_ident_num,
    from cte1_unions
    group by all
), cte3_add_columns as (
    select 
        max(t.score) as score,
        t.equi_id,
        any_value(t1.equi_name) as equi_name,
        any_value(t1.class) as class,
        any_value(t1.functional_location) as functional_location,
        any_value(t1.tech_ident_num) as tech_ident_num,
    from cte2_grouped as t
    join equipment t1 on t1.equi_id = t.equi_id
    group by t.equi_id,
)
select * from cte3_add_columns
where score > 0.0
order by score desc;

