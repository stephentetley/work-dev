--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The schema `base_macros" exists.
--

create or replace macro base_macros.convert_to_millimetres(units varchar, sz decimal) as (
with cte1_common as (
    select lower(units) as unitsu
), cte2_worker as ( 
    select 
    case 
        when unitsu = 'mm' or unitsu = 'millimetres' then sz
        when unitsu = 'cm' or unitsu = 'centimetres'  then sz * 10.0
        when unitsu = 'm'  or unitsu = 'metres' then sz * 1000.0
        when unitsu = 'in' or unitsu = 'inch' or unitsu = 'inches' then sz * 25.4
        when unitsu = 'feet' then sz * 304.8
        else null
    end as answer
    from cte1_common
) 
select round(answer, 0) from cte2_worker
);

create or replace macro base_macros.convert_to_metres(units varchar, sz decimal) as (
with cte1_common as (
    select lower(units) as unitsu
), cte2_worker as ( 
    select 
    case 
        when unitsu = 'mm' or unitsu = 'millimetres' then sz * 1000.0
        when unitsu = 'cm' or unitsu = 'centimetres'  then sz * 100.0
        when unitsu = 'm'  or unitsu = 'metres' then sz
        when unitsu = 'in' or unitsu = 'inch' or unitsu = 'inches' then sz / 39.37
        when unitsu = 'feet' then sz / 3.281
        else null
    end as answer
    from cte1_common
) select try_cast(round(answer, 0) as integer) from cte2_worker
);


create or replace macro base_macros.convert_to_litres_per_second(units varchar, fl decimal) as (
with cte1_common as (
    select lower(units) as unitsu
), cte2_worker as ( 
    select 
    case 
        when unitsu = 'l/s' or unitsu = 'litres per second' then fl
        when unitsu = 'l/min' or unitsu = 'litre per minute' then fl / 60.0
        when unitsu = 'l/hr'  or unitsu = 'litre per hour' then fl / 3600.0
        when unitsu = 'm³/s' or unitsu = 'cubic metre per second' then fl * 1000
        when unitsu = 'm³/h' or unitsu = 'cubic metre per hour' then fl * 3.6
        else null
    end as answer
    from cte1_common
) 
select round(answer, 3) from cte2_worker
);


create or replace macro base_macros.convert_to_cubic_metres_per_hour(units varchar, fl decimal) as (
with cte1_common as (
    select lower(units) as unitsu
), cte2_worker as ( 
    select 
    case 
        when unitsu = 'l/s' or unitsu = 'litres per second' then fl * 3.6
        when unitsu = 'l/min' or unitsu = 'litre per minute' then fl / 16.667
        when unitsu = 'l/hr'  or unitsu = 'litre per hour' then fl / 1000.0
        when unitsu = 'm³/s' or unitsu = 'cubic metre per second' then fl * 3600.0
        when unitsu = 'm³/h' or unitsu = 'cubic metre per hour' then fl
        else null
    end as answer
    from cte1_common
) 
select round(answer, 3) from cte2_worker
);

create or replace macro base_macros.convert_to_kilowatts(units varchar, pw decimal) as (
with cte1_common as (
    select lower(units) as unitsu
), cte2_worker as ( 
    select 
    case 
        when unitsu = 'kw' or unitsu = 'kilowatts' then pw
        when unitsu = 'w' or unitsu = 'watts' then pw / 1000.0
        else null
    end as answer
    from cte1_common
) 
select round(answer, 3) from cte2_worker
);


