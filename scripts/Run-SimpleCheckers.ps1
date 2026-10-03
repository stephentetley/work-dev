param (
    [Parameter(Mandatory=$false)][string]$FlocWorklist,
    [Parameter(Mandatory=$false)][string]$EquiWorklist,
    [Parameter(Mandatory=$true)][string]$OutFile
)


$assetUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "../asset_utils"
$assetUtilsPath = [System.IO.Path]::GetFullPath($assetUtilsPath)

duckdb $OutFile -c ".read $assetUtilsPath/simple_file_checkers/sql/01_setup_checker_tables.sql"

if ($null -ne $FlocWorklist) {
    duckdb $OutFile -c "set variable floc_srcfile = `"$FlocWorklist`";" `
        -c ".read $assetUtilsPath/simple_file_checkers/sql/02_import_simple_floc.sql"
}

if ($null -ne $EquiWorklist) {
    duckdb $OutFile -c "set variable equi_srcfile = `"$EquiWorklist`";" `
        -c ".read $assetUtilsPath/simple_file_checkers/sql/03_import_simple_equi.sql"
}

duckdb $OutFile `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/floc_checks/simple_floc_checks.sql" `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/equi_checks/simple_equi_checks.sql" `
    -c ".read $assetUtilsPath/simple_file_checkers/sql/equi_checks/super_equi_checks.sql" `
    -c "select * from checker_results" `


Write-Output "Wrote: $OutFile"
