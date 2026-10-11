create schema if not exists s4_hierarchy;
create schema if not exists input;
create schema if not exists facts;

-- drop type translation_type;
create type translation_type AS ENUM ('system', 'subsystem');


-- The output...
create or replace table s4_hierarchy.floc_translation (
    s4_site_funcloc varchar not null,
    translation_range translation_type,
    "function" varchar,
    process_group varchar,
    process varchar,
    system_index integer,
    system_description varchar,
    system_class varchar,
    system_class_description varchar,
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


-- -- "Fact data"
-- create or replace table facts.sites (
--     ai2_site_name varchar not null,
--     s4_site_code varchar not null,
-- );

-- "Fact data"
create or replace table facts.level6_floc_codes (
    subsys_objtype varchar not null,
    subsys_floc_prefix varchar not null,
);

create or replace temporary macro make_system_tag(sys_ix integer) as 
    format('SYS{:02d}', coalesce(sys_ix, 0));

create or replace temporary macro make_system_name(sys_fstring varchar, sys_ix integer) as 
    format(coalesce(sys_fstring, 'SYSTEM {}'), coalesce(sys_ix, 0));

create or replace temporary macro make_subsys_tag(prefix3 varchar, sys_ix integer) as 
    format('{}{:02d}', coalesce(prefix3 , '###'), coalesce(sys_ix, 0));

create or replace temporary macro make_subsys_name(subsys_fstring varchar, subsys_ix integer) as 
    format(coalesce(subsys_fstring, 'SUBSYSTEM {}'), coalesce(subsys_ix, 0));

create or replace view s4_hierarchy.vw_annotate_flocs as
select 
    t.s4_site_funcloc as s4_site,
    t."function",
    t.process_group,
    t.process,
    make_system_tag(t1.system_index) as system,
    make_system_name(t1.system_fstring, t1.system_index) as system_description,
    t1.system_class as system_class,
    format(t2.fstring, t1.subsys_index) as subsys,
    -- make_subsys_name(t2.fstring, t2.subsys_index) as subsys_description,
    -- 'PUMP' as subsys_objtype,
from s4_hierarchy.floc_translation t
left join input.user_annos t1 on t1.pli_num = t.primary_equi_plinum
left join asset_facts.level6_floc_mask_codes t2 on t2.object_type = t.subsys_objtype
