--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The schema `base_macros" exists.
--


create or replace macro base_macros.format_signal3
    (smin integer, smax integer, units varchar) as format('{} - {} {}', smin, smax, upper(units)),
    (smin decimal, smax decimal, units varchar) as format('{:.0f} - {:.0f} {}', smin, smax, upper(units));

-- # Enums


create or replace macro base_macros.acdc_3_to_voltage_units(units varchar) as (
with cte1_common as (
    select upper(units) as unitsu
), cte2_worker as (
    select case 
        when t.unitsu in ('AC', 'ALTERNATING CURRENT')    then 'VAC'
        when t.unitsu in ('DC', 'DIRECT CURRENT')         then 'VDC'
        else null
    end as answer
    from cte1_common t
)
select answer from cte2_worker);

-- Excel may try to turn these into dates...
create or replace macro base_macros.bdfv_757_to_bridge_vehicles_per_day(val varchar) as (
with cte1_common as (
    select upper(val) as valu
), cte2_worker as (
    select 
        case 
            when valu = '1-10'   or valu = '01-Oct' then '1 - 10'
            when valu = '11-50'  or valu = '11-Nov' then '11 - 50'
            when valu = '51-100' or valu = '51-100' then '51 - 100'
            when valu = '101+'                      then '101 PLUS'
            else null
        end as answer
    from cte1_common
)
select answer from cte2_worker);


create or replace macro base_macros.cafl_435_to_kisk_cat_flap_available(val varchar) as (
with cte1_common as (
    select upper(val) as valu
), cte2_worker as (
    select 
        case 
            when valu = 'C+H' or valu = 'CABLE AND HOSE' then 'YES'
            when valu = 'CABLE' then 'YES'
            when valu = 'NONE'  then 'NO'
        else null
        end as answer
    from cte1_common
)
select answer from cte2_worker);



create or replace macro base_macros.kosk_471_to_kisk_material(val varchar) as (
with cte1_common as (
    select upper(val) as valu
), cte2_worker as (
    select 
        case 
            when valu = 'GRP'  or valu = 'GRP'   then 'GLASS REINFORCED PLasTIC'
            when valu = 'STEL' or valu = 'STEEL' then 'STEEL'
            when valu = 'BRK'  or valu = 'BRICK' then 'BRICK'
            else null
        end as answer
    from cte1_common
)   
select answer from cte2_worker);



create or replace macro base_macros.lity_388_to_pump_lifting_type(val varchar) as (
with cte1_common as (
    select upper(val) as valu
), cte2_worker as (
    select 
        case 
            when valu = 'BR'  or valu = 'BLUE ROPE' then 'BLUE ROPE'
            when valu = 'CHN' or valu = 'CHAIN'     then 'CHAIN'
            else null
        end as answer
    from cte1_common
)
select answer from cte2_worker);



create or replace macro base_macros.rngu_132_to_anal_range_unit(val varchar) as (
case 
    when val = 'HAZN'    or val = 'Hazen' then 'HAZEN'
    when val = 'M'       or val = 'm'     then 'M'
    when val = 'MBAR'    or val = 'mbar'  then 'MBAR'
    when val = 'MGL'     or val = 'mg/l'  then 'MG/L'
    when val = 'MSCM'    or val = 'µS/cm' then 'MS/CM'
    when val = 'NTU'     or val = 'NTU'   then 'NTU'
    when val = 'PH'      or val = 'pH'    then 'PH'
    when val = 'Deg C'   or val = 'Deg C' then 'DEG C'
    when val = 'Deg F'   or val = 'Deg F' then 'DEG F'
    when val = 'pp/m'    or val = 'pp/m'  then 'PPM'
    when val = 'Bar'     or val = 'Bar'   then 'BAR'
    when val = 'l/h'     or val = 'l/h'   then 'L/H'
    when val = 'l/s'     or val = 'l/s'   then 'L/S'
    when val = 'FTU'     or val = 'Formazine Turbidity Unit' then 'FTU'
    when val = 'Ml/d'    or val = 'Ml/d'  then 'ML/D'
    when val = 'm3/d'    or val = 'm3/d'  then 'M3/D'
    when val = 'm3/h'    or val = 'm3/h'  then 'M3/H'
    when val = 'Percent' or val = '%'     then 'PCT'
    when val = 'Kg/h'    or val = 'Kg/h'  then 'KG/H'
    when val = 'g/l'     or val = 'g/l'   then 'G/L'
    when val = 'mm'      or val = 'mm'    then 'MM'
    when val = 'm/s'     or val = 'm/s'   then 'M/S'
    when val = 'kPa'     or val = 'kPa'   then 'KPA'
    when val = 'cm/s'    or val = 'cm/s'  then 'CM/S'
    when val = 'kg'      or val = 'kg'    then 'KG'
    when val = 'W/m2'    or val = 'W/m2'  then 'W/M2'
    when val = 'mV'      or val = 'mV'    then 'MV'
    when val = 'Nm3Hr'   or val = 'Nm3/h' then 'NM3/H'
    when val = 'Am3/h'   or val = 'Am3/h' then 'AM3/H'
    when val = 'mmH2o'   or val = 'mmH2o' then 'MM H2O'
    else null
end);


create or replace macro base_macros.swpt_815_to_vepr_swp_type(val varchar) as (
with cte1_common as (
    select upper(val) as valu
), cte2_worker as (
    select 
        case 
            when valu = 'GEN' or valu = 'GENERIC - SAFEGUARD' then 'GENERIC'
            when valu = 'BES' or valu = 'BESPOKE - IMS'       then 'BESPOKE'
            else null
        end as answer
    from cte1_common
)
select answer from cte2_worker);



create or replace macro base_macros.wlun_337_to_swl_units(val varchar) as (
with cte1_common as (
    select upper(val) as valu
), cte2_worker as (
    select 
        case 
            when valu = 'KG'    or valu = 'KILOGRAM'               then 'KG'
            when valu = 'KW'    or valu = 'KILOWATT'               then 'KW'
            when valu = 'T'     or valu = 'TONNE'                  then 'TON'
            when valu = 'TON'   or valu = 'TON (UK)'               then 'TON (UK)'
            when valu = 'CWT'   or valu = 'HUNDREDWEIGHT'          then 'CWT'
            when valu = 'KJ/KG' or valu = 'KILOJOULE PER KILOGRAM' then 'KJ/KG'
            when valu = 'A'     or valu = 'UAMPERE'                then 'A'
            when valu = 'KN'    or valu = 'KILONEWTON'             then 'KN'
            when valu = 'MAN'   or valu = 'MAN'                    then 'MAN'
            else null
        end as answer
    from cte1_common
)
select answer from cte2_worker);






