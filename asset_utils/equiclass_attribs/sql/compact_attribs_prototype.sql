load excel;

set variable worklist = 'compact_attribs1.xlsx';

-- Note the trim trick with `all_varchar` to remove all extra padding
-- and "excel offset" for row_ix
create or replace table worklist_landing as
select 
    1 + row_number() over () as row_ix,
    trim(columns(t.*)),
from read_xlsx(
    getvariable('worklist'), 
    sheet = 'EquiAttribs', 
    all_varchar = true) t;

-- from worklist_landing;

create or replace table answers as
with cte1_unpivot as (
    unpivot worklist_landing
    on columns(lambda c: c like 'Attribute%' or c like 'Value%')
    into
        name cname
        value cvalue
), cte2_classified as (
    select 
        t."Equipment" as equi_id,
        t."Class" as class_name,
        case 
            when t.cname like 'Attribute%' then 'attr' 
            when t.cname like 'Value%' then 'value'
            else null
        end as row_type,
        if (row_type = 'attr', t.cvalue, null) as attr_name,
        if (row_type = 'value', t.cvalue, null) as attr_value,
        try_cast(regexp_extract(t.cname, '^\p{L}+(\d+)$', 1) as integer) as index,
    from cte1_unpivot t
    where t.cvalue is not null
)
select 
    t.equi_id,
    t.class_name,
    t1.attr_name as characteristics,
    t.attr_value as char_value
from cte2_classified t
join cte2_classified t1 
    on t1.equi_id = t.equi_id
    and t1.index = t.index
    and t1.row_type = 'attr'
where t.attr_value is not null;

copy (
    select * from answers order by equi_id, class_name, characteristics
) to 'answers.csv' (format csv, header true);