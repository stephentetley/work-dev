
<#
    Paths need sorting out - currently this should be run 
    from the top of `work-dev`
#>


param (
    [Parameter(Mandatory=$true)][string]$Worklist,
    [Parameter(Mandatory=$true)][string]$OutFile
)

<#
    Eventually the dependency on asset_lake will be replaced
    probably by an API GET.
#>

$ZtableFlocdes = "../../../../work/resources/ztables/zt_flocdes_20260205.XLSX"
$AssetLakePath = "../../../work/2026/asset_lake/asset_lake.ducklake"

duckdb -c "set variable floc_delta_worklist = `"$Worklist`";" `
    -c "set variable ztable_flocdes = `"$ZtableFlocdes`";" `
    -c "attach 'ducklake:$AssetLakePath' as asset_lake (READ_ONLY);" `
    -c "attach '$OutFile' as sqlite_db (type sqlite);" `
    -c ".read ./asset_utils/excel_uploader/sql/create_sqlite_tables.sql" `
    -c ".read ./asset_utils/floc_delta/sql/01_create_floc_delta_tables.sql" `
    -c ".read ./asset_utils/floc_delta/sql/02_import_files.sql" `
    -c ".read ./asset_utils/floc_delta/sql/03_floc_delta_insert_into.sql" `
    -c ".read ./asset_utils/floc_delta/sql/04_excel_uploader_insert_into.sql" `
    -c "detach sqlite_db;" `
    -c "detach asset_lake;"

Write-Output "Wrote: $OutFile"
