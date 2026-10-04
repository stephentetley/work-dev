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

create or replace table simple_floc_worklist (
    source_row integer,
    batch_number integer,
    functional_location varchar not null,
    floc_name varchar not null,
    floc_category integer,
    str_indicator varchar,
    floc_type varchar,
    level5_system_class varchar,
    level5_system_name varchar,
    startup_date date,
    position integer,
    maint_plant integer,
    cost_center integer,
    main_work_center varchar,
    plant_section varchar,
    installation_allowed boolean,
    user_status varchar,
    ai2_sai_number varchar,
    grid_ref varchar,
    easting integer,
    northing integer,
    solution_id varchar,
    primary key (source_row)
);


create or replace table simple_equi_worklist (
    source_row integer,
    batch_number integer,
    temp_id varchar not null,
    equi_name varchar,
    category varchar,
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
    primary key (source_row)
);








