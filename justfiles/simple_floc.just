

setup worklist :
    mkdir -p .simple_floc

    duckdb -init duckrc \
        -c "set variable source_simple_floc_xlsx = '{{worklist}}';" \
        -c "set variable dest_simple_floc_parquet = '.simple_floc/simple_floc.parquet';" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_floc/gen_parquet.sql" \
        -f "shutdownrc"


check :
    duckdb -init duckrc \
        -c "attach '.simple_floc/simple_floc.parquet' as simple_floc_worklist;" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_file_checkers/setup_checker_tables.sql" \
        -c ".tables"    \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_file_checkers/floc_checks/simple_floc_checks.sql" \
        -c "select * from checker_results;" \
        -c "detach simple_floc_worklist;" \
        -f "shutdownrc"


export basefilename :
    duckdb -init duckrc \
        -c "set variable simple_floc_parquet = '.simple_floc/simple_floc.parquet';" \
        -c "attach '.simple_floc/simple_floc.sqlite' as sqlite_db (type sqlite);" \
        -c ".read $WORK_DEV_ROOT/asset_utils/excel_uploader/create_sqlite_tables.sql" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_floc/excel_uploader_insert_into.sql" \
        -c "detach sqlite_db;" \
        -f "shutdownrc"

    dotnet run --project $WORK_CSHARP_ROOT/SptUtils/GenExcelUpload \
        --database_file .simple_floc/simple_floc.sqlite \
        --output_folder . \
        --output_basename {{basefilename}}

