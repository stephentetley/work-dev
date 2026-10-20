-- asset_facts is attached

load fts;

create or replace table equitype as
select 
    t.class_name[1:4] as objtype,
    t.class_name as class, 
    t.class_description as description,
    concat_ws(' ', lower(objtype), lower(class), lower(t.class_description)) as text_content,
from asset_facts.s4_classlists.equi_classlist t
where t.char_name = 'LOCATION_ON_SITE'
order by class;

PRAGMA create_fts_index(
    'equitype', 'class', 'text_content', overwrite = 1
);

create or replace macro search_equitype(str varchar) as table
select
    fts_main_equitype.match_bm25(class, str) as score,
    objtype, 
    class,
    description,
from equitype
where score is not null
order by score desc;

from search_equitype('scraper bridge');
