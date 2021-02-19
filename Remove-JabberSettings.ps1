$LocalFiles = Test-Path $env:USERPROFILE'\AppData\Local\Cisco\Unified Communications\Jabber\'
$RoamingFiles = Test-Path $env:USERPROFILE'\AppData\Roaming\Cisco\Unified Communications\Jabber\'
$ProgramData = Test-Path 'C:\ProgramData\Cisco Systems\Cisco Jabber'

If ($LocalFiles){
    Remove-Item -LiteralPath $env:USERPROFILE'\AppData\Local\Cisco\Unified Communications\Jabber\' -Force -Recurse
}

If ($RoamingFiles){
    Remove-Item -LiteralPath $env:USERPROFILE'\AppData\Roaming\Cisco\Unified Communications\Jabber\' -Force -Recurse
}

If ($ProgramData){
    $confirmation = Read-Host "Remove ProgramData? [y/n]"
    if ($confirmation -eq 'y') {
        Remove-Item -LiteralPath 'C:\ProgramData\Cisco Systems\Cisco Jabber' -Force -Recurse
    }
}