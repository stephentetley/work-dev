


floc-delta existing-flocs worklist dest :
    duckdb -init duckrc \
        -c "set variable existing_flocs_parquet = '{{existing-flocs}}';" \
        -c "set variable floc_delta_worklist_xlsx = '{{worklist}}';" \
        -c "set variable dest_simple_floc_xlsx = '{{dest}}';" \
        -f "$WORK_DEV_ROOT/asset_utils/floc_delta/floc_delta.sql" \
        -f "shutdownrc"

gen-minimal-floc-parquet ih06xlsx dest :
    duckdb -init duckrc \
        -c "set variable source_ih06_xlsx = '{{ih06xlsx}}';" \
        -c "set variable dest_minimal_floc_parquet = '{{dest}}';" \
        -f "$WORK_DEV_ROOT/asset_utils/gen_parquet/ih06_minimal_floc/ih06_minimal_floc.sql" \
        -f "shutdownrc"
