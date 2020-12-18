<#
#Debug: Remove all sessions
Get-PsSession |?{$s.State.value__ -ne 2 -or $_.Availability -ne 1}|Remove-PSSession -Verbose
#>

$debug = $false

Import-module MicrosoftTeams
 
if($debug -like $true){
    Write-Host "  DEBUG: Trying to connect to existing session..." -ForegroundColor DarkGray
}
$pssession = Get-PSSession -name SfbPowerShell* | Where-Object {$_.Availability -eq 1}
if($pssession.count -eq 0){
    if($debug -like $true){
        Write-Host "  DEBUG: Connecting to Skype Online..." -ForegroundColor DarkGray
    }
    try{
        $sfboSession = New-CsOnlineSession
    }
    Catch{
        $errOutput = [PSCustomObject]@{
            status = "failed"
            error = $_.Exception.Message
            step = "Connecting to Skype Online"
            cmdlet = "New-CsOnlineSession"
        }
        Write-Output ( $errOutput | ConvertTo-Json)
        exit
    }
    if($debug -like $true){
        Write-Host "  DEBUG: Importing PS Session..." -ForegroundColor DarkGray
    }
    try{
        Import-PSSession $sfboSession -AllowClobber
    }
    Catch{
        $errOutput = [PSCustomObject]@{
            status = "failed"
            error = $_.Exception.Message
            step = "Importing PS Session"
            cmdlet = "Import-PSSession"
        }
        Write-Output ( $errOutput | ConvertTo-Json)
        exit
    }
}