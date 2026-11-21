
create schema if not exists simple_equi;


create or replace table simple_equi.simple_equi (
    source_file varchar,
    source_row bigint,
    batch_number integer,
    temp_id varchar not null,
    equi_name varchar not null,
    equi_category varchar,
    functional_location varchar,
    super_equi_id varchar,
    equi_type varchar,
    equi_class varchar,
    weight_kg decimal,
    startup_date date,
    manufacturer varchar,
    model_number varchar,
    manuf_part_number varchar,
    manuf_serial_number varchar,
    position integer,
    tech_ident_number varchar,
    user_status varchar,
    ai2_pli_number varchar,
    ai2_sai_number varchar,
    location_on_site varchar,
    grid_ref varchar,
    easting integer,
    northing integer,
    solution_id varchar,
    condition_grade varchar,
    condition_grade_reason varchar,
    survey_year integer,
    primary key (temp_id)
);

create or replace macro get_equiclass_fields(classname varchar) as (
with cte1_tups as (
    select row(char_description, ddl_data_type) as tup from asset_facts.s4_classlists.equi_classlist where class_name = classname order by char_ix
), cte2_agg as (
    select array_agg(t.tup) as agg from cte1_tups t
) select any_value(t.agg) from cte2_agg t);


