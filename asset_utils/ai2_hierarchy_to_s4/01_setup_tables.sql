create schema if not exists s4_hierarchy;
create schema if not exists input;

-- The output...
create or replace table s4_hierarchy.flocs (
    s4_site varchar not null,
    "function" varchar,
    process_group varchar,
    process varchar,
    system varchar,
    system_description varchar,
    system_class varchar,
    subsys varchar,
    subsys_description varchar,
    subsys_objtype varchar,
    -- include the equipment used to determine the floc
    primary_equi_plinum varchar,
);

create or replace table input.ai2_equi (
    pli_num varchar not null,
    common_name varchar not null,
    site_name varchar,
    process_1_2 varchar,
    equipment_type varchar,
);

-- supplied and resupplied by the user annotated until all flocs translated
create or replace table input.user_annos (
    pli_num varchar not null,
    ai2_description varchar not null,
    system_index integer,
    system_fstring varchar,
    system_class varchar,
    subsys_index integer,
    subsys_fstring varchar,
);


-- "Fact data"
create or replace table input.sites (
    ai2_site_name varchar not null,
    s4_site_code varchar not null,
);
