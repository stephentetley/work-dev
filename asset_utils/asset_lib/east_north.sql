--
-- Copyright 2026 Stephen Tetley
-- 
-- Use of this source code is governed by the Apache 2.0 license
-- that can be found in the LICENSE file.
--

-- Preliminaries: 
-- The schema `asset_lib" as been created.
--


create or replace macro asset_lib.get_east_north(gridref varchar) as (
with cte_major as (
    select * from
        (values
            ('S', 0,        0),
            ('T', 500_000,  0),
            ('N', 0,        500_000),
            ('O', 500_000,  500_000),
            ('H', 0,        1_000_000),
        ) east_north_major(ix, east, north)
), cte_minor as (
    select * from
        (values
            ('A', 0,         400_000),
            ('B', 100_000,   400_000),
            ('C', 200_000,   400_000),
            ('D', 300_000,   400_000),
            ('E', 400_000,   400_000),
            ('F', 0,         300_000),
            ('G', 100_000,   300_000),
            ('H', 200_000,   300_000),
            ('J', 300_000,   300_000),
            ('K', 400_000,   300_000),
            ('L', 0,         200_000),
            ('M', 100_000,   200_000),
            ('N', 200_000,   200_000),
            ('O', 300_000,   200_000),
            ('P', 400_000,   200_000),
            ('Q', 0,         100_000),
            ('R', 100_000,   100_000),
            ('S', 200_000,   100_000),
            ('T', 300_000,   100_000),
            ('U', 400_000,   100_000),
            ('V', 0,         0),
            ('W', 100_000,   0),
            ('X', 200_000,   0),
            ('Y', 300_000,   0),
            ('Z', 400_000,   0),
        ) east_north_minor(ix, east, north)
), cte1_get_parts as (
    select
        upper(gridref[1]) as major_letter,
        upper(gridref[2]) as minor_letter,
        try_cast(gridref[3:7] as integer) as east1,
        try_cast(gridref[8:12] as integer) as north1,
), cte2_make_answer as (
    select
        t_major.east + t_minor.east + t.east1 AS easting,
        t_major.north + t_minor.north + t.north1 AS northing,
    from cte1_get_parts t
    left join cte_major t_major on t_major.ix = t.major_letter
    left join cte_minor t_minor on t_minor.ix = t.minor_letter
)
select
    struct_pack(easting := cte2_make_answer.easting, northing := cte2_make_answer.northing)
from cte2_make_answer);



