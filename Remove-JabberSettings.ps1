$LocalFiles = Test-Path $env:USERPROFILE'\AppData\Local\Cisco\Unified Communications\Jabber\'
$RoamingFiles = Test-Path $env:USERPROFILE'\AppData\Roaming\Cisco\Unified Communications\Jabber\'

If ($LocalFiles){
    Remove-Item -LiteralPath $env:USERPROFILE'\AppData\Local\Cisco\Unified Communications\Jabber\' -Force -Recurse
}

If ($RoamingFiles){
    Remove-Item -LiteralPath $env:USERPROFILE'\AppData\Roaming\Cisco\Unified Communications\Jabber\' -Force -Recurse
}