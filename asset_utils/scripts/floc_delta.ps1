
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

$assetUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$assetUtilsPath = [System.IO.Path]::GetFullPath($assetUtilsPath)

$workPath = $Env:MY_WORK_DIR

if ([string]::IsNullOrEmpty($workPath)) {
    Write-Host "The environment variable MY_WORK_DIR is not set"
    exit
}

$ztableFlocdes = "$workPath/resources/ztables/zt_flocdes_20260205.XLSX"
$assetLakePath = "$workPath/2026/asset_lake/asset_lake.ducklake"

duckdb -c "set variable floc_delta_worklist = `"$Worklist`";" `
    -c "set variable ztable_flocdes = `"$ztableFlocdes`";" `
    -c "attach 'ducklake:$assetLakePath' as asset_lake (READ_ONLY);" `
    -c "attach '$OutFile' as sqlite_db (type sqlite);" `
    -c ".read $assetUtilsPath/excel_uploader/sql/create_sqlite_tables.sql" `
    -c ".read $assetUtilsPath/floc_delta/sql/01_create_floc_delta_tables.sql" `
    -c ".read $assetUtilsPath/floc_delta/sql/02_import_files.sql" `
    -c ".read $assetUtilsPath/floc_delta/sql/03_floc_delta_insert_into.sql" `
    -c ".read $assetUtilsPath/floc_delta/sql/04_excel_uploader_insert_into.sql" `
    -c "detach sqlite_db;" `
    -c "detach asset_lake;"

Write-Output "Wrote: $OutFile"
