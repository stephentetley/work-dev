--
-- Copyright 2026 Stephen Tetley
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
-- http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 


-- Preliminaries: 
-- Must have a SQLite database attached called `sqlite_db`
-- This script is run from DuckDB - i.e. it relies on the SQLite extension 
-- (which must be already loaded). There is no necessity for a 
-- standalone SQLite to be installed 


-- Floc Create tables


create or replace table sqlite_db.floc_create_change_request_header (
    change_request varchar,
    change_request_description varchar,
    "priority" varchar,
    due_date varchar,
);

create or replace table sqlite_db.floc_create_change_request_notes (
    notes varchar,
);


-- includes `batch_number` which is not printed in the Excel file
create or replace table sqlite_db.floc_create_functional_location (
    batch_number integer not null,
    functional_location varchar not null,
    floc_description varchar,
    category varchar,
    str_indicator varchar,
    inactive varchar,
    object_type varchar,
    authoriz_group varchar,
    gross_weight varchar,
    unit_of_weight varchar,
    inventory_no varchar,
    size_dimens varchar,
    start_up_date varchar,
    acquisition_value varchar,
    currency varchar,
    acquistion_date varchar,
    manufacturer varchar,
    model_number varchar,
    manuf_part_no varchar,
    manuf_serial_no varchar,
    manuf_country varchar,
    construct_year varchar,
    construct_mth varchar,
    maint_plant varchar,
    "location" varchar, 
    room varchar,
    plant_section varchar,
    work_center varchar,
    abc_indic varchar,
    sort_field varchar,
    business_area varchar,
    asset varchar,
    sub_number varchar,
    cost_center varchar,
    wbs_element varchar,
    standg_order varchar,
    settlement_order varchar,
    planning_plant varchar,
    planner_group varchar,
    main_work_ctr varchar,
    plnt_work_center varchar,
    catalog_profile varchar,
    sup_funct_loc varchar,
    position varchar,
    ref_location varchar,
    installation_allowed varchar,
    single_inst varchar,
    construction_type varchar,
    status_profile varchar,
    user_status varchar,
    status_of_an_object varchar,
    status_without_stsno varchar,
    begin_guarantee_c varchar,
    warranty_end_c varchar,
    master_warranty_c varchar,
    inherit_warranty_c varchar,
    pass_on_warranty_c varchar,
    begin_guarantee_v varchar,
    warranty_end_v varchar,
    master_warranty_v varchar,
    inherit_warranty_v varchar,
    pass_on_warranty_v varchar,
    sales_org varchar,
    distr_channel varchar,
    division varchar,
    sales_office varchar,
    sales_group varchar
);


-- includes `batch_number` which is not printed in the Excel file
create or replace table sqlite_db.floc_create_classification (
    batch_number integer,
    functional_location varchar,
    class varchar,
    characteristics varchar,
    char_value varchar
);

-- Floc Change tables

create or replace table sqlite_db.floc_change_change_request_header (
    change_request varchar,
    change_request_description varchar,
    "priority" varchar,
    due_date varchar,
);

create or replace table sqlite_db.floc_change_change_request_notes (
    notes varchar,
);


-- includes `batch_number` which is not printed in the Excel file
create or replace table sqlite_db.floc_change_functional_location (
    batch_number integer not null,
    functional_location varchar not null,
    floc_description varchar,
    inactive varchar,
    object_type varchar,
    authoriz_group varchar,
    gross_weight varchar,
    unit_of_weight varchar,
    inventory_no varchar,
    size_dimens varchar,
    start_up_date varchar,
    acquisition_value varchar,
    currency varchar,
    acquistion_date varchar,
    manufacturer varchar,
    model_number varchar,
    manuf_part_no varchar,
    manuf_serial_no varchar,
    manuf_country varchar,
    construct_year varchar,
    construct_mth varchar,
    maint_plant varchar,
    "location" varchar, 
    room varchar,
    plant_section varchar,
    work_center varchar,
    abc_indic varchar,
    sort_field varchar,
    business_area varchar,
    asset varchar,
    sub_number varchar,
    cost_center varchar,
    wbs_element varchar,
    standg_order varchar,
    settlement_order varchar,
    planning_plant varchar,
    planner_group varchar,
    main_work_ctr varchar,
    plnt_work_center varchar,
    catalog_profile varchar,
    sup_funct_loc varchar,
    position varchar,
    installation_allowed varchar,
    single_inst varchar,
    construction_type varchar,
    status_profile varchar,
    user_status varchar,
    status_of_an_object varchar,
    status_without_stsno varchar,
    begin_guarantee_c varchar,
    warranty_end_c varchar,
    master_warranty_c varchar,
    inherit_warranty_c varchar,
    pass_on_warranty_c varchar,
    begin_guarantee_v varchar,
    warranty_end_v varchar,
    master_warranty_v varchar,
    inherit_warranty_v varchar,
    pass_on_warranty_v varchar,
    sales_org varchar,
    distr_channel varchar,
    division varchar,
    sales_office varchar,
    sales_group varchar
);


-- includes `batch_number` which is not printed in the Excel file
create or replace table sqlite_db.floc_change_classification (
    batch_number integer,
    functional_location varchar,
    class varchar,
    characteristics varchar,
    char_value varchar,
    class_delete_ind varchar
);

-- Equi Create tables

create or replace table sqlite_db.equi_create_change_request_header (
    change_request varchar,
    change_request_description varchar,
    priority varchar,
    due_date varchar,
);

create or replace table sqlite_db.equi_create_change_request_notes (
    notes varchar,
);


-- includes `batch_number` which is not printed in the Excel file
create or replace table sqlite_db.equi_create_equipment_data (
    batch_number integer not null,
    equipment varchar not null,
    equip_category varchar,
    description_medium varchar,
    valid_from varchar,
    inactive varchar,
    object_type varchar,
    authoriz_group varchar,
    gross_weight varchar,
    unit_of_weight varchar,
    inventory_no varchar,
    size_dimens varchar,
    start_up_date varchar,
    acquisition_value varchar,
    currency varchar,
    acquistion_date varchar,
    manufacturer varchar,
    model_number varchar,
    manuf_part_no varchar,
    manuf_serial_number varchar,
    manuf_country varchar,
    construct_year varchar,
    construct_mth varchar,
    maint_plant varchar,
    plant_section varchar,
    "location" varchar,
    room varchar,
    abc_indi varchar,
    work_center varchar,
    sort_field varchar,
    business_area varchar,
    asset varchar,
    sub_number varchar,
    cost_center varchar,
    wbs_element varchar,
    standg_order varchar,
    settlement_order varchar,
    planning_plant varchar,
    planner_group varchar,
    main_work_ctr varchar,
    plnt_work_center varchar,
    catalog_profile varchar,
    functional_loc varchar,
    superord_equip varchar,
    position varchar,
    tech_ident_no varchar,
    construction_type_ma varchar,
    material varchar,
    material_serial_numb varchar,
    config_material varchar,
    status_profile varchar,
    status_of_an_object varchar,
    status_without_stsno varchar,
    sales_org varchar,
    distr_channel varchar,
    division varchar,
    sales_office varchar,
    sales_group varchar,
    license_no varchar,
    begin_guarantee_c varchar,
    warranty_end_c varchar,
    master_warranty_c varchar,
    inherit_warranty_c varchar,
    pass_on_warranty_c varchar,
    begin_guarantee_v varchar,
    warranty_end_v varchar,
    master_warranty_v varchar,
    inherit_warranty_v varchar,
    pass_on_warranty_v varchar,
    vendor varchar,
    customer varchar,
    end_customer varchar,
    cur_customer varchar,
    operator varchar,
    delivery_date varchar,
);


-- includes `batch_number` which is not printed in the Excel file
create or replace table sqlite_db.equi_create_classification (
    batch_number integer,
    equipment varchar,
    class varchar,
    characteristics varchar,
    char_value varchar
);

-- Equi Change tables

create or replace table sqlite_db.equi_change_change_request_header (
    change_request varchar,
    change_request_description varchar,
    priority varchar,
    due_date varchar,
);

create or replace table sqlite_db.equi_change_change_request_notes (
    notes varchar,
);


-- includes `batch_number` which is not printed in the Excel file
create or replace table sqlite_db.equi_change_equipment_data (
    batch_number integer not null,
    equipment varchar not null,     -- A
    description_medium varchar,     -- B
    inactive varchar,               -- C
    object_type varchar,            -- D
    authoriz_group varchar,         -- E
    gross_weight varchar,           -- F
    unit_of_weight varchar,         -- G
    inventory_no varchar,           -- H
    size_dimens varchar,            -- I
    start_up_date varchar,          -- J
    acquisition_Value varchar,      -- K
    currency varchar,               -- L
    acquistion_date varchar,        -- M
    manufacturer varchar,           -- N
    model_number varchar,           -- O
    manuf_part_no varchar,          -- P
    manuf_serial_number varchar,    -- Q
    manuf_country varchar,          -- R
    construct_year varchar,         -- S
    construct_mth varchar,          -- T
    maint_plant varchar,            -- U
    plant_section varchar,          -- V
    "location" varchar,             -- W
    room varchar,                   -- X
    abc_indi varchar,               -- Y
    work_center varchar,            -- Z
    sort_field varchar,             -- AA
    business_area varchar,          -- AB
    asset varchar,                  -- AC
    sub_number varchar,             -- AD
    cost_center varchar,            -- AE
    wbs_element varchar,            -- AF
    standg_order varchar,           -- AG
    settlement_order varchar,       -- AH
    planning_plant varchar,         -- AI
    planner_group varchar,          -- AJ
    main_work_ctr varchar,          -- AK
    plnt_work_center varchar,       -- AL
    catalog_profile varchar,        -- AM
    functional_loc varchar,         -- AN
    superord_equip varchar,         -- AO
    position varchar,               -- AP
    tech_ident_no varchar,          -- AQ
    construction_type_ma varchar,   -- AR
    material varchar,               -- AS
    material_serial_numb varchar,   -- AT
    config_material varchar,        -- AU
    status_profile varchar,         -- AV
    status_of_an_object varchar,    -- AW
    status_without_stsno varchar,   -- AX
    sales_org varchar,              -- AY
    distr_channel varchar,          -- AZ
    division varchar,               -- BA
    sales_office varchar,           -- BB
    sales_group varchar,            -- BC
    license_no varchar,             -- BD
    begin_guarantee_c varchar,      -- BE
    warranty_end_c varchar,         -- BF
    master_warranty_c varchar,      -- BG
    inherit_warranty_c varchar,     -- BH
    pass_on_warranty_c varchar,     -- BI
    begin_guarantee_v varchar,      -- BJ
    warranty_end_v varchar,         -- BK
    master_warranty_v varchar,      -- BL
    inherit_warranty_v varchar,     -- BM
    pass_on_warr_v varchar,         -- BN
    vendor varchar,                 -- BO
    customer varchar,               -- BP
    end_customer varchar,           -- BQ
    cur_customer varchar,           -- BR
    operator varchar,               -- BS
    delivery_date varchar           -- BT          
);


-- includes `batch_number` which is not printed in the Excel file
create or replace table sqlite_db.equi_change_classification (
    batch_number integer,
    equipment varchar,
    class varchar,
    characteristics varchar,
    char_value varchar,
    class_delete_ind varchar
);

