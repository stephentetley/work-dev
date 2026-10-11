--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The schema `asset_lib" as been created.
--


create or replace macro asset_lib.ai2_is_pump(equipment_type varchar) as
equipment_type like '% PUMP';

create or replace macro asset_lib.ai2_is_valve(equipment_type varchar) as
equipment_type like '% VALVE' 
or equipment_type like '% VALVES' 
or equipment_type like '% VALVE - WASTE' 
or equipment_type like '% VALVE - CLEAN' 
or equipment_type like '% VALVE (WATER)' 
or equipment_type like '% VALVE (GAS)';

create or replace macro asset_lib.ai2_is_fixed_lifting(equipment_type varchar) as
equipment_type in (
    'CRANES',
    'BEAM TROLLEY'
    'DAVIT SOCKET',
    'GANTRIES',
    'LIFTS',
    'RUNWAYS',
);

create or replace macro asset_lib.ai2_is_portable_lifting(equipment_type varchar) as
equipment_type in (
    'DAVIT', 
    'FALL ARRESTER',
    'JIB CRANE',
    'MOBILE HYDRAULIC LIFTERS'
);

create or replace macro asset_lib.ai2_is_pressure_vessel(equipment_type varchar) as
equipment_type like '% RECEIVER' 
or equipment_type in (
    'VACUUM VESSEL', 
    'OZONE GENERATOR',
    'GAS HOLDER',
    'AUTOCLAVE WELDED CONSTRUCTION'
);

create or replace macro asset_lib.ai2_is_tank(equipment_type varchar) as
equipment_type like '% TANK' 
or equipment_type like '%WATER STORAGE'
or equipment_type in (
    'WW LAGOON'
);

create or replace macro asset_lib.ai2_is_conveyor(equipment_type varchar) as
equipment_type = 'CONVEYORS';

create or replace macro asset_lib.ai2_is_centrifuge(equipment_type varchar) as
equipment_type = 'CENTRIFUGE';

create or replace macro asset_lib.ai2_is_fan(equipment_type varchar) as
equipment_type in ('FAN', 'AIR CONDITIONING FAN');

create or replace macro asset_lib.ai2_is_kiosk(equipment_type varchar) as
equipment_type = 'KIOSK';

create or replace macro asset_lib.ai2_is_macerator(equipment_type varchar) as
equipment_type = 'MACIPUMP';

create or replace macro asset_lib.ai2_is_mixer(equipment_type varchar) as
equipment_type = 'STIRRERS, MIXERS + AGITATORS';

create or replace macro asset_lib.ai2_is_process_filter(equipment_type varchar) as
equipment_type like '% FILTER' 
or equipment_type like '% FILTERS' 
or equipment_type = 'FILTER COMPONENT';

create or replace macro asset_lib.ai2_is_scraper_bridge(equipment_type varchar) as
equipment_type = 'SCRAPERS';

create or replace macro asset_lib.ai2_is_screen(equipment_type varchar) as
equipment_type = 'SCREENS'
or equipment_type like '% SCREEN' ;

create or replace macro asset_lib.ai2_is_strainer(equipment_type varchar) as
equipment_type = 'STRAINER'
or equipment_type like '% STRAINER';

create or replace macro asset_lib.ai2_is_well(equipment_type varchar) as
equipment_type = 'DRY WELL'
or equipment_type = 'WET WELL';

