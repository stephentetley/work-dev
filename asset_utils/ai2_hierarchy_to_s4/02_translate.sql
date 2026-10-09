create or replace temporary macro make_system_tag(sys_ix integer) as 
    format('SYS{:02d}', coalesce(sys_ix, 0));

create or replace temporary macro make_system_name(sys_fstring varchar, sys_ix integer) as 
    format(coalesce(sys_fstring, 'SYSTEM {}'), coalesce(sys_ix, 0));

create or replace temporary macro make_subsys_tag(prefix3 varchar, sys_ix integer) as 
    format('{}{:02d}', coalesce(prefix3 , '###'), coalesce(sys_ix, 0));

create or replace temporary macro make_subsys_name(subsys_fstring varchar, subsys_ix integer) as 
    format(coalesce(subsys_fstring, 'SUBSYSTEM {}'), coalesce(subsys_ix, 0));


insert into s4_hierarchy.flocs by name
select 
    t.s4_site_code as s4_site,
    'SSS' as function,
    'SCS' as process_group,
    'CEP' as process,
    make_system_tag(t2.system_index) as system,
    make_system_name(t2.system_fstring, t2.system_index) as system_description,
    t2.system_class as system_class,
    make_subsys_tag('PMP', t2.subsys_index) as subsys,
    make_subsys_name(t2.subsys_fstring, t2.subsys_index) as subsys_description,
    'PUMP' as subsys_objtype,
from input.sites t
join input.ai2_equi t1 on t1.site_name = t.ai2_site_name
left join input.user_annos t2 on t2.pli_num = t1.pli_num
where t1.process_1_2 = 'CHEMICAL SERVICES/SODIUM HYPOCHLORITE STORAGE'
and t1.equipment_type in ('DIAPHRAGM PUMP');


