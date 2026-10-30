
ih0608 ih06_src ih08_src name :
    mkdir -p .ih0608

    duckdb -init duckrc \
        -c "set variable source_ih06_xlsx = '{{ih06_src}}';" \
        -c "set variable dest_minimal_floc_parquet = '.ih0608/minimal_floc.parquet';" \
        -f "$WORK_DEV_ROOT/asset_utils/gen_parquet/ih06_minimal_floc/ih06_minimal_floc.sql" \
        -f "shutdownrc"

    duckdb -init duckrc \
        -c "set variable source_ih08_xlsx = '{{ih08_src}}';" \
        -c "set variable dest_minimal_equi_parquet = '.ih0608/minimal_equi.parquet';" \
        -f "$WORK_DEV_ROOT/asset_utils/gen_parquet/ih08_minimal_equi/ih08_minimal_equi.sql" \
        -f "shutdownrc"

    duckdb -init duckrc \
        -c "set variable floc_minimal_source_parquet = '.ih0608/minimal_floc.parquet';" \
        -c "set variable equi_minimal_source_parquet = '.ih0608/minimal_equi.parquet';" \
        -c "set variable dest_report_xlsx = '{{name}}_ih0608.xlsx';" \
        -f "$WORK_DEV_ROOT/asset_utils/reports/ih0608/ih0608.sql" \
        -f "shutdownrc"
