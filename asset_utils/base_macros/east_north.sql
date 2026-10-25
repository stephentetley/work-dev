--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The schema `base_macros" exists.
--


create or replace macro base_macros.get_east_north(gridref varchar) as (
with cte1_major as (
    select 
        case upper(gridref[1])
            when 'S' then struct_pack(east := 0,        north := 0)
            when 'T' then struct_pack(east := 500_000,  north := 0)
            when 'N' then struct_pack(east := 0,        north :=500_000)
            when 'O' then struct_pack(east := 500_000,  north :=500_000)
            when 'H' then struct_pack(east := 0,        north :=1_000_000)
            else null
        end as answer
), cte2_minor(answer) as (
    select 
        case upper(gridref[2])
            when 'A' then struct_pack(east :=  0,         north := 400_000)
            when 'B' then struct_pack(east :=  100_000,   north := 400_000)
            when 'C' then struct_pack(east :=  200_000,   north := 400_000)
            when 'D' then struct_pack(east :=  300_000,   north := 400_000)
            when 'E' then struct_pack(east :=  400_000,   north := 400_000)
            when 'F' then struct_pack(east :=  0,         north := 300_000)
            when 'G' then struct_pack(east :=  100_000,   north := 300_000)
            when 'H' then struct_pack(east :=  200_000,   north := 300_000)
            when 'J' then struct_pack(east :=  300_000,   north := 300_000)
            when 'K' then struct_pack(east :=  400_000,   north := 300_000)
            when 'L' then struct_pack(east :=  0,         north := 200_000)
            when 'M' then struct_pack(east :=  100_000,   north := 200_000)
            when 'N' then struct_pack(east :=  200_000,   north := 200_000)
            when 'O' then struct_pack(east :=  300_000,   north := 200_000)
            when 'P' then struct_pack(east :=  400_000,   north := 200_000)
            when 'Q' then struct_pack(east :=  0,         north := 100_000)
            when 'R' then struct_pack(east :=  100_000,   north := 100_000)
            when 'S' then struct_pack(east :=  200_000,   north := 100_000)
            when 'T' then struct_pack(east :=  300_000,   north := 100_000)
            when 'U' then struct_pack(east :=  400_000,   north := 100_000)
            when 'V' then struct_pack(east :=  0,         north := 0)
            when 'W' then struct_pack(east :=  100_000,   north := 0)
            when 'X' then struct_pack(east :=  200_000,   north := 0)
            when 'Y' then struct_pack(east :=  300_000,   north := 0)
            when 'Z' then struct_pack(east :=  400_000,   north := 0)
            else null
        end as answer
), cte3_numeric_parts as (
    select
        try_cast(gridref[3:7] as integer) as east1,
        try_cast(gridref[8:12] as integer) as north1,
), cte4_worker as (
    select
        tmajor.answer.east + tminor.answer.east + t.east1 AS easting1,
        tmajor.answer.north + tminor.answer.north + t.north1 AS northing1,
        struct_pack(easting := easting1, northing := northing1) as answer,
    from cte3_numeric_parts t, 
        cte1_major tmajor, 
        cte2_minor tminor
)
select answer from cte4_worker);


create or replace macro base_macros.get_gridref(easting integer, northing integer) as (
with cte1_find_major as (
    select 
        easting as e,
        northing as n,
        case 
            when e >= 0       and e < 500_000   and n >= 0         and n < 500_000   then 'S'
            when e >= 500_000 and e < 1_000_000 and n >= 0         and n < 500_000   then 'T'
            when e >= 0       and e < 500_000   and n >= 500_000   and n < 1_000_000 then 'N'
            when e >= 500_000 and e < 1_000_000 and n >= 500_000   and n < 1_000_000 then 'O'
            when e >= 0       and e < 500_000   and n >= 1_000_000 and n < 1_500_000 then 'H'
            when e >= 500_000 and e < 1_000_000 and n >= 1_000_000 and n < 1_500_000 then 'J'
            else null
        end as answer
), cte2_find_minor as (
    select 
        easting % 500000 as e,
        northing % 500000 as n,
        case 
            when e >= 0       and e < 100_000     and n >= 0       and n < 100_000 then 'V'
            when e >= 100_000 and e < 200_000     and n >= 0       and n < 100_000 then 'W'
            when e >= 200_000 and e < 300_000     and n >= 0       and n < 100_000 then 'X'
            when e >= 300_000 and e < 400_000     and n >= 0       and n < 100_000 then 'Y'
            when e >= 400_000 and e < 500_000     and n >= 0       and n < 100_000 then 'Z'
            when e >= 0       and e < 100_000     and n >= 100_000 and n < 200_000 then 'Q'
            when e >= 100_000 and e < 200_000     and n >= 100_000 and n < 200_000 then 'R'
            when e >= 200_000 and e < 300_000     and n >= 100_000 and n < 200_000 then 'S'
            when e >= 300_000 and e < 400_000     and n >= 100_000 and n < 200_000 then 'T'
            when e >= 400_000 and e < 500_000     and n >= 100_000 and n < 200_000 then 'U'
            when e >= 0       and e < 100_000     and n >= 200_000 and n < 300_000 then 'L'
            when e >= 100_000 and e < 200_000     and n >= 200_000 and n < 300_000 then 'M'
            when e >= 200_000 and e < 300_000     and n >= 200_000 and n < 300_000 then 'N'
            when e >= 300_000 and e < 400_000     and n >= 200_000 and n < 300_000 then 'O'
            when e >= 400_000 and e < 500_000     and n >= 200_000 and n < 300_000 then 'P'
            when e >= 0       and e < 100_000     and n >= 300_000 and n < 400_000 then 'F'
            when e >= 100_000 and e < 200_000     and n >= 300_000 and n < 400_000 then 'G'
            when e >= 200_000 and e < 300_000     and n >= 300_000 and n < 400_000 then 'H'
            when e >= 300_000 and e < 400_000     and n >= 300_000 and n < 400_000 then 'J'
            when e >= 400_000 and e < 500_000     and n >= 300_000 and n < 400_000 then 'K'
            when e >= 0       and e < 100_000     and n >= 400_000 and n < 500_000 then 'A'
            when e >= 100_000 and e < 200_000     and n >= 400_000 and n < 500_000 then 'B'
            when e >= 200_000 and e < 300_000     and n >= 400_000 and n < 500_000 then 'C'
            when e >= 300_000 and e < 400_000     and n >= 400_000 and n < 500_000 then 'D'
            when e >= 400_000 and e < 500_000     and n >= 400_000 and n < 500_000 then 'E'
            else null
        end as answer
), cte3_worker as (
    select
        tmajor.answer as major_char,
        tminor.answer as minor_char,
        easting % 100000 as small_e,
        northing % 100000 as small_n,
        format('{}{}{:05d}{:05d}', major_char, minor_char, small_e, small_n) as answer,
    from cte1_find_major tmajor, cte2_find_minor tminor
)
select answer from cte3_worker);

