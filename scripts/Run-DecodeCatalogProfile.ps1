param (
    [Parameter(Mandatory=$true)][string]$Worklist,
    [Parameter(Mandatory=$true)][string]$OutFile
)


$assetUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "../asset_utils"
$assetUtilsPath = [System.IO.Path]::GetFullPath($assetUtilsPath)


duckdb -c "set variable srcfile = `"$Worklist`";" `
    -c ".read $assetUtilsPath/decode_catalog_profile/sql/decode_catalog_profile.sql" `
    -c "copy (select * from xtable_catalog_profile_classes) to '$OutFile' (format csv, header, delimiter ',');"


Write-Output "Wrote: $OutFile"
