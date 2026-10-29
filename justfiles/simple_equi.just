

setup worklist :
    mkdir -p .simple_equi

    duckdb -init duckrc \
        -c "set variable source_simple_equi_xlsx = '{{worklist}}';" \
        -c "set variable dest_simple_equi_parquet = '.simple_equi/simple_equi.parquet';" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_equi/gen_parquet.sql" \
        -f "shutdownrc"


check :
    duckdb -init duckrc \
        -c "attach '.simple_equi/simple_equi.parquet' as simple_equi_worklist;" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_file_checkers/setup_checker_tables.sql" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_file_checkers/equi_checks/simple_equi_checks.sql" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_file_checkers/equi_checks/super_equi_checks.sql" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_file_checkers/equi_checks/temp_id_checks.sql" \
        -c "select * from checker_results;" \
        -c "detach simple_equi_worklist;" \
        -f "shutdownrc"


export basefilename :
    duckdb -init duckrc \
        -c "set variable simple_equi_parquet = '.simple_equi/simple_equi.parquet';" \
        -c "attach '.simple_equi/simple_equi.sqlite' as sqlite_db (type sqlite);" \
        -c ".read $WORK_DEV_ROOT/asset_utils/excel_uploader/create_sqlite_tables.sql" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_equi/excel_uploader_insert_into.sql" \
        -c "detach sqlite_db;" \
        -f "shutdownrc"

    dotnet run --project $WORK_CSHARP_ROOT/SptUtils/GenExcelUpload \
        --database_file .simple_equi/simple_equi.sqlite \
        --output_folder . \
        --output_basename {{basefilename}}

