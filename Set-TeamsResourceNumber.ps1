<#
PowerShell script to assign Direct Route phone numbers and Voice Policies to users
By Ruud van Strijp - Axians
ruud.vanstrijp@axians.com

#Requirements
Microsoft Teams module needs to be installed into PowerShell
Install-Module MicrosoftTeams -AllowClobber

#Usage
.\Set-TeamsResourceNumber.ps1 -upn <upn> -PhoneNumber <lineURI> (all optional)
If upn and lineURI are left empty, they will be requested
If upn does not contain an @, the script will exit

#Examples
.\Set-TeamsResourceNumber
.\Set-TeamsResourceNumber -upn firstname.lastname@domain.com -PhoneNumber +31123456789
#>

Param (
[Parameter (Mandatory = $true)][string]$upn,
[Parameter (Mandatory = $true)][string]$PhoneNumber
)
 
$debug = $true
 
import-module MicrosoftTeams
 
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


if($debug -like $true){
    Write-Host "  DEBUG: Processing line: $($upn) " -ForegroundColor DarkGray
}
#Correct User
if($upn -notmatch "\@"){
    Write-Host "  WARNING: Not a UPN: "-ForegroundColor yellow -NoNewline
    Write-Host "$($upn)" -ForegroundColor green -NoNewline
    exit
}
#Correct Number
if($PhoneNumber -notlike "+*"){
    $PhoneNumber = "+"+$PhoneNumber
    if($debug -like $true){
        Write-Host "  DEBUG: Added +" -ForegroundColor DarkGray
    }
}


Write-Host "  Updating Online Application Instance: " -ForegroundColor White -NoNewLine
Write-Host "$($upn)" -ForegroundColor Green -NoNewLine
Write-Host " with " -ForegroundColor White -NoNewLine
Write-Host "$($PhoneNumber)" -ForegroundColor Green -NoNewline


#Check if the number is already assigned to another resource account
$getApplicationInstance = Get-CsOnlineApplicationInstance -WarningAction SilentlyContinue | Where-Object -Property PhoneNumber -Like -Value "*$PhoneNumber*"

if($getApplicationInstance -and $getApplicationInstance.UserPrincipalName -ne $upn){
    Write-Host "  ERROR: Number already assigned to Online Application Instance: " -ForegroundColor Red -NoNewLine
    Write-Host "$($getApplicationInstance.DisplayName)" -ForegroundColor Green -NoNewline
    Write-Host " with UPN " -ForegroundColor Red -NoNewLine
    Write-Host "$($getApplicationInstance.UserPrincipalName)" -ForegroundColor Green
    exit
}

#Enable user and assign phone number
if($debug -like $true){
    Write-Host "  DEBUG: Attempting to Configure Phone Number" -ForegroundColor DarkGray
}
try{
    Set-CsOnlineApplicationInstance -Identity $upn -OnpremPhoneNumber $PhoneNumber
}
Catch{
    $errOutput = [PSCustomObject]@{
        status = "failed"
        error = $_.Exception.Message
        step = "SetCsOnlineApplicationInstance"
        cmdlet = "Set-CsOnlineApplicationInstance"
    }
    Write-Output ( $errOutput | ConvertTo-Json)
    exit
}

Write-Host "Warning: Changing phone number might take some time to update; above might still display the old number" -ForegroundColor yellow
#Remove-PSSession $sfboSession