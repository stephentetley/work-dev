param (
    [Parameter(Mandatory=$true)][string]$FlocWorklist,
    [Parameter(Mandatory=$true)][string]$AssetLakePath,
    [Parameter(Mandatory=$true)][string]$OutFile
)


$assetUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "../asset_utils"
$assetUtilsPath = [System.IO.Path]::GetFullPath($assetUtilsPath)

duckdb $OutFile -c "attach 'ducklake:$AssetLakePath' as asset_lake (READ_ONLY);" `
    -c "set variable floc_srcfile = `"$FlocWorklist`";" `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/01_setup_checker_tables.sql" `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/02_import_simple_floc.sql" `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/floc_checks/simple_floc_checks.sql" `
    -c "select * from checker_results;" `
    -c "detach asset_lake;"


Write-Output "Wrote: $OutFile"
