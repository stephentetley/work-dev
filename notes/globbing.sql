-- generate a file like this...

set variable xlsx_source_glob = '*.xlsx';

create or replace temporary table table1 as
with cte1_raw as (
    select
        row_number() over () as row_ix,
        file,
    from glob(getvariable('xlsx_source_glob'))
), cte2_commands as (
    select
        format('set variable source_ai2_xlsx = ''{}'';', file) as set_source,
        format('set variable dest_ai2_parquet = ''ai2_export_{:03d}.parquet'';', row_ix) as set_dest,
        format('.read ''{}/asset_utils/gen_parquet/ai2_export/ai2_export.sql''', getenv('WORK_DEV_ROOT')) as run_script,
    from cte1_raw
)
select concat_ws(E'\n', set_source, set_dest, run_script, E'\n') as sql_text from cte2_commands;

copy (select sql_text from table1)
to 'process_ai2_exports_generated.sql' (format csv, header false, quote '');
