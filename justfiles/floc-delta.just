

run-floc-delta ih06-xlsx worklist-xlsx upload-prefix :
    mkdir -p .flocdelta
    just floc-delta::ih06-to-parquet {{ih06-xlsx}}
    just floc-delta::make-deltas-xlsx {{worklist-xlsx}}
    just floc-delta::simple-floc-to-parquet
    just floc-delta::check-simple-floc
    just floc-delta::gen-upload-file {{upload-prefix}}

ih06-to-parquet ih06xlsx :
    duckdb -init duckrc \
        -c "set variable source_ih06_xlsx = '{{ih06xlsx}}';" \
        -c "set variable dest_minimal_floc_parquet = '.flocdelta/existing_flocs.parquet';" \
        -f "$WORK_DEV_ROOT/asset_utils/gen_parquet/ih06_minimal_floc/ih06_minimal_floc.sql" \
        -f "shutdownrc"

make-deltas-xlsx worklist-xlsx :
    duckdb -init duckrc \
        -c "set variable existing_flocs_parquet = '.flocdelta/existing_flocs.parquet';" \
        -c "set variable floc_delta_worklist_xlsx = '{{worklist-xlsx}}';" \
        -c "set variable dest_simple_floc_xlsx = '.flocdelta/new_delta_flocs.xlsx';" \
        -f "$WORK_DEV_ROOT/asset_utils/floc_delta/floc_delta.sql" \
        -f "shutdownrc"


simple-floc-to-parquet :
    duckdb -init duckrc \
        -c "set variable source_simple_floc_xlsx = '.flocdelta/new_delta_flocs.xlsx';" \
        -c "set variable dest_simple_floc_parquet = '.flocdelta/new_deltas_simple_floc.parquet';" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_floc/gen_parquet.sql" \
        -f "shutdownrc"


check-simple-floc :
    duckdb -init duckrc \
        -c "attach '.flocdelta/new_deltas_simple_floc.parquet' as simple_floc_worklist;" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_file_checkers/setup_checker_tables.sql" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_file_checkers/floc_checks/simple_floc_checks.sql" \
        -c "select * from checker_results;" \
        -c "detach simple_floc_worklist;" \
        -f "shutdownrc"

gen-upload-file upload-prefix :
    duckdb -init duckrc \
        -c "set variable simple_floc_parquet = '.flocdelta/new_deltas_simple_floc.parquet';" \
        -c "attach '.flocdelta/new_floc_delta.sqlite' as sqlite_db (type sqlite);" \
        -c ".read $WORK_DEV_ROOT/asset_utils/excel_uploader/create_sqlite_tables.sql" \
        -c ".read $WORK_DEV_ROOT/asset_utils/simple_floc/excel_uploader_insert_into.sql" \
        -c "detach sqlite_db;" \
        -f "shutdownrc"

    dotnet run --project $WORK_CSHARP_ROOT/SptUtils/GenExcelUpload \
        --database_file .flocdelta/new_floc_delta.sqlite \
        --output_folder . \
        --output_basename {{upload-prefix}}

