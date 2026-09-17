param (
    [Parameter(Mandatory=$true)][string]$EquiWorklist,
    [Parameter(Mandatory=$true)][string]$EquiOutFile,
    [Parameter(Mandatory=$true)][int]$Easting,
    [Parameter(Mandatory=$true)][int]$Northing
)


$assetUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$assetUtilsPath = [System.IO.Path]::GetFullPath($assetUtilsPath)

duckdb -c "set variable update_en_equi_worklist = `"$EquiWorklist`";" `
    -c "set variable easting = `"$Easting`";" `
    -c "set variable northing = `"$Northing`";" `
    -c "attach '$EquiOutFile' as sqlite_db (type sqlite);" `
    -c ".read $assetUtilsPath/excel_uploader/sql/create_sqlite_tables.sql" `
    -c ".read $assetUtilsPath/update_east_north/sql/B1_update_east_north_equi.sql" `
    -c "detach sqlite_db;"

Write-Output "Wrote: $EquiOutFile"
