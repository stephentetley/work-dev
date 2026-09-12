
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

duckdb -c "set variable simple_equi_worklist = `"$Worklist`";" `
    -c "attach '$OutFile' as sqlite_db (type sqlite);" `
    -c ".read $assetUtilsPath/excel_uploader/sql/create_sqlite_tables.sql" `
    -c ".read $assetUtilsPath/simple_equi/sql/01_create_simple_equi_tables.sql" `
    -c ".read $assetUtilsPath/simple_equi/sql/02_import_equi.sql" `
    -c ".read $assetUtilsPath/simple_equi/sql/03_excel_uploader_insert_into.sql" `
    -c "detach sqlite_db;"

Write-Output "Wrote: $OutFile"
