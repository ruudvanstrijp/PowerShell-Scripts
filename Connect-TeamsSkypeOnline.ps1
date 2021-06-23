<#

.NOTES
Importing PS Session is only needed until Teams Module v1.1.6. After version 2, connecting is easier and SFB Online modules don't need to be loaded separately.

Upgrade to the latest module:
Uninstall-Module -Name MicrosoftTeams -AllVersions
Install-Module -Name MicrosoftTeams -Force -Scope AllUsers


.NOTES
#Debug: Remove all sessions
Get-PsSession |?{$s.State.value__ -ne 2 -or $_.Availability -ne 1}|Remove-PSSession -Verbose
#>

Param (
[Parameter (Mandatory = $false)][string]$domain
)

$debug = $true

Import-module MicrosoftTeams

$teamsModuleVersion = (Get-InstalledModule -Name MicrosoftTeams).Version

if($teamsModuleVersion -gt 2.0.0){
    if($debug -like $true){
        Write-Host "  DEBUG: Teams Module greater than 2.0.0, connecting directly to Teams" -ForegroundColor DarkGray
    }
    Connect-MicrosoftTeams
}
else{

    if($debug -like $true){
        Write-Host "  DEBUG: Trying to connect to existing session..." -ForegroundColor DarkGray
    }

    $pssession = Get-PSSession -name SfbPowerShell* | Where-Object {$_.Availability -eq 1}
    if($pssession.count -eq 0){

        if($domain){
            if($debug -like $true){
                Write-Host "  DEBUG: Connecting to Skype Online on domain $($domain)..." -ForegroundColor DarkGray
            }
            try{
                $sfboSession = New-CsOnlineSession -OverrideAdminDomain $domain
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
        }else{
            if($debug -like $true){
                Write-Host "  DEBUG: Connecting to Skype Online on the default domain..." -ForegroundColor DarkGray
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
}

Write-Host "  Connected to tenant: " -ForegroundColor White -NoNewLine
Write-Host (Get-CsTenant).DisplayName -ForegroundColor Green

$tenantIdentity = (Get-CsTenant).Identity -replace ".*lync","" -replace "001.*",""
$adminURL = "https://admin$($tenantIdentity).online.lync.com/HostedMigration/hostedmigrationService.svc"

Write-Host "  Admin URL: " -ForegroundColor White -NoNewLine
Write-Host $adminURL -ForegroundColor Green