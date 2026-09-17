param (
    [Parameter(Mandatory=$true)][string]$FlocWorklist,
    [Parameter(Mandatory=$true)][string]$FlocOutFile,
    [Parameter(Mandatory=$true)][int]$Easting,
    [Parameter(Mandatory=$true)][int]$Northing
)


$assetUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$assetUtilsPath = [System.IO.Path]::GetFullPath($assetUtilsPath)

duckdb -c "set variable update_en_floc_worklist = `"$FlocWorklist`";" `
    -c "set variable easting = `"$Easting`";" `
    -c "set variable northing = `"$Northing`";" `
    -c "attach '$FlocOutFile' as sqlite_db (type sqlite);" `
    -c ".read $assetUtilsPath/excel_uploader/sql/create_sqlite_tables.sql" `
    -c ".read $assetUtilsPath/update_east_north/sql/A1_update_east_north_floc.sql" `
    -c "detach sqlite_db;"

Write-Output "Wrote: $FlocOutFile"
