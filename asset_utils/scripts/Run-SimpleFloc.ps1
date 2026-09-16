param (
    [Parameter(Mandatory=$true)][string]$Worklist,
    [Parameter(Mandatory=$true)][string]$OutFile
)


$assetUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$assetUtilsPath = [System.IO.Path]::GetFullPath($assetUtilsPath)

duckdb -c "set variable simple_floc_worklist = `"$Worklist`";" `
    -c "attach '$OutFile' as sqlite_db (type sqlite);" `
    -c ".read $assetUtilsPath/excel_uploader/sql/create_sqlite_tables.sql" `
    -c ".read $assetUtilsPath/simple_floc/sql/01_create_simple_floc_tables.sql" `
    -c ".read $assetUtilsPath/simple_floc/sql/02_import_floc.sql" `
    -c ".read $assetUtilsPath/simple_floc/sql/03_excel_uploader_insert_into.sql" `
    -c "detach sqlite_db;"

Write-Output "Wrote: $OutFile"
