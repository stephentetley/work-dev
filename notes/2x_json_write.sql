-- 2x_json_write
-- Writing one json file containing two tables with different schema

load json;

create or replace table table1 as
select t.* from values ('bob', 60), ('jim', 70) as t(name, score);


create or replace table table2 as
select t.* from values ('bob', 2), ('jim', 1) as t(name, position);



create or replace temporary table json_tabs as
with cte_table1_json(tab, rowobj) as (
    select
        'table1' as tab,
        struct_pack(name := name, score := score) as rowobj
    from table1
), cte_table2_json(tab, rowobj) as (
    select
        'table2' as tab,
        struct_pack(name := name, position := position) as rowobj
    from table2
), cte_grouped as (
    select tab, json_group_array(rowobj) as jsonrows from cte_table1_json group by tab
    union
    select tab, json_group_array(rowobj) as jsonrows from cte_table2_json group by tab
)
select * from cte_grouped order by tab;

-- write JSON
copy json_tabs to 'tabbed.json' (format json);


-- see what we have
select * from json_tabs;


create or replace table tabs (name varchar, jsonrows json);

insert into tabs
select *
from read_json('tabbed.json');

-- This doesn't help because the structure in `from_json(_, structure)` must be a literal

-- create or replace macro columns_to_json(cols tuple(varchar, varchar)[]) as  (
-- with cte1_rows as (
--     select t[1] as k, t[2] as v from unnest(cols) t
-- )
-- select json_group_object(k, v) from cte1_rows);
--
--
-- select columns_to_json([('name', 'varchar'), ('score', 'integer')]);



-- colspec must be a literal...
create or replace macro get_table(filename varchar, tablename varchar, colspec varchar) as table (
select
     unnest(from_json(t.jsonrows, '[' || colspec || ']'), recursive := true)
from
    read_json(filename) t
where t.tab = tablename);

.print 'deserialize...'

create or replace table table1_back as
select * from get_table('tabbed.json', 'table1', '{"name": "varchar", "score": "integer"}');


select * from table1_back;

create or replace table table2_back as
select * from get_table('tabbed.json', 'table2', '{"name": "varchar", "position": "integer"}');

select * from table2_back;




