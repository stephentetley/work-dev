param (
    [Parameter(Mandatory=$true)][string]$Selectors,
    [Parameter(Mandatory=$true)][string]$FlocWorklist,
    [Parameter(Mandatory=$true)][string]$EquiWorklist,
    [Parameter(Mandatory=$true)][string]$OutFile
)


$assetUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$assetUtilsPath = [System.IO.Path]::GetFullPath($assetUtilsPath)

duckdb `
    -c "set variable floc_selectors = `"$Selectors`";" `
    -c "set variable update_en_floc_worklist = `"$FlocWorklist`";" `
    -c "set variable update_en_equi_worklist = `"$EquiWorklist`";" `
    -c "attach '$OutFile' as sqlite_db (type sqlite);" `
    -c ".read $assetUtilsPath/excel_uploader/sql/create_sqlite_tables.sql" `
    -c ".read $assetUtilsPath/update_east_north/sql/update_east_north.sql" `
    -c "detach sqlite_db;"

Write-Output "Wrote: $OutFile"
