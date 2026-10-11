

insert into s4_hierarchy.floc_translation by name
select 
    t1.s4_site_funcloc as s4_site_funcloc,
    'subsystem'::translation_type as translation_range,
    'SSS' as function,
    'SCS' as process_group,
    'CEP' as process,
    null as system_index,
    null as system_class,

    -- make_system_tag(t2.system_index) as system,
    -- make_system_name(t2.system_fstring, t2.system_index) as system_description,
    -- t2.system_class as system_class,
    -- make_subsys_tag('PMP', t2.subsys_index) as subsys,
    -- make_subsys_name(t2.subsys_fstring, t2.subsys_index) as subsys_description,
    'PUMP' as subsys_objtype,
    t.pli_num as primary_equi_plinum,
from input.ai2_equi t
join asset_facts.site_mapping t1 on t1.ai2_installation_name = t.site_name
where t.process_1_2 = 'CHEMICAL SERVICES/SODIUM HYPOCHLORITE STORAGE'
and t.equipment_type in ('DIAPHRAGM PUMP');


insert into s4_hierarchy.floc_translation by name
select 
    t1.s4_site_funcloc as s4_site_funcloc,
    'system'::translation_type as translation_range,
    'CAA' as function,
    'NET' as process_group,
    'TEL' as process,
    null as system_index,
    'CTOSSY' as system_class,
    null as system_description,
    'RTS TELEMETRY SYSTEM' as system_class_description,
    t.pli_num as primary_equi_plinum,
from input.ai2_equi t
join asset_facts.site_mapping t1 on t1.ai2_installation_name = t.site_name
where t.process_1_2 = 'CONTROL SERVICES/RTS MONITORING'
and t.equipment_type in ('TELEMETRY OUTSTATION');

insert into s4_hierarchy.floc_translation by name
select 
    t1.s4_site_funcloc as s4_site_funcloc,
    'system'::translation_type as translation_range,
    'SMS' as function,
    'LFT' as process_group,
    'FLT' as process,
    1 as system_index,
    'Fixed Lifting' as system_description,
    'SLFSSY' as system_class,
    'FIXED LIFTING SYSTEM' as system_class_description,
    null as primary_equi_plinum,
from input.ai2_equi t
join asset_facts.site_mapping t1 on t1.ai2_installation_name = t.site_name
where t.process_1_2 = 'STATUTORY/LIFTING EQUIPMENT'
and t.equipment_type in ('DAVIT SOCKET');

insert into s4_hierarchy.floc_translation by name
select 
    t1.s4_site_funcloc as s4_site_funcloc,
    'system'::translation_type as translation_range,
    'SMS' as function,
    'LFT' as process_group,
    'PRL' as process,
    1 as system_index,
    'Portable Lifting' system_description,
    'SLFSSY' as system_class,
    'PORTABLE LIFTING SYSTEM' as system_class_description,
    null as primary_equi_plinum,
from input.ai2_equi t
join asset_facts.site_mapping t1 on t1.ai2_installation_name = t.site_name
where t.process_1_2 = 'STATUTORY/LIFTING EQUIPMENT'
and t.equipment_type in ('DAVIT');
