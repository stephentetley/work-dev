param (
    [Parameter(Mandatory=$true)][string]$EquiWorklist,
    [Parameter(Mandatory=$true)][string]$AssetLakePath,
    [Parameter(Mandatory=$true)][string]$OutFile
)


$assetUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "../asset_utils"
$assetUtilsPath = [System.IO.Path]::GetFullPath($assetUtilsPath)

duckdb $OutFile -c "attach 'ducklake:$AssetLakePath' as asset_lake (READ_ONLY);" `
    -c "set variable equi_srcfile = `"$EquiWorklist`";" `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/01_setup_checker_tables.sql" `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/03_import_simple_equi.sql" `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/equi_checks/simple_equi_checks.sql" `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/equi_checks/super_equi_checks.sql" `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/equi_checks/temp_id_checks.sql" `
    -c "select * from checker_results;" `
    -c "detach asset_lake;"


Write-Output "Wrote: $OutFile"
