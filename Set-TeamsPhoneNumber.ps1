<#
.SYNOPSIS
PowerShell script to assign Direct Route phone numbers and Voice Policies to users
By Ruud van Strijp - Axians
ruud.vanstrijp@axians.com

.NOTES
Microsoft Teams module 2.3.1 or higher needs to be installed into PowerShell
Uninstall-Module -Name MicrosoftTeams -AllVersions
Install-Module -Name MicrosoftTeams -Force -Scope AllUsers
If you have an older version, use my Connect-TeamsSkypeOnline.ps1 script to connect to Teams first

.EXAMPLE
.\Set-TeamsPhoneNumber.ps1 -upn <upn> -lineURI <lineURI> -voiceRoutingPolicy <voiceRoutingPolicy> (all optional)
If upn and lineURI are left empty, they will be requested
If voiceRoutingPolicy is left empty, all existing policies will be queried and a selection can be made
If upn does not contain an @, the script assumes the user's Display Name is entered and it will try to look up the corresponding upn

.EXAMPLE
.\Set-TeamsPhoneNumber
.\Set-TeamsPhoneNumber -upn firstname.lastname@domain.com -lineURI +31123456789
.\Set-TeamsPhoneNumber -upn firstname.lastname@domain.com -lineURI +31123456789 -voiceRoutingPolicy Unrestricted
.\Set-TeamsPhoneNumber -upn "fistname lastname" -lineURI +31123456789 -voiceRoutingPolicy Unrestricted

.NOTES
#Debug: Remove all sessions
Get-PsSession |?{$s.State.value__ -ne 2 -or $_.Availability -ne 1}|Remove-PSSession -Verbose
#>

Param (
[Parameter (Mandatory = $true)][string]$upn,
[Parameter (Mandatory = $true)][string]$lineURI,
[Parameter (Mandatory = $false)][string]$voiceRoutingPolicy
)
 
$debug = $true
 
import-module MicrosoftTeams

if($debug -like $true){
    Write-Host "  DEBUG: Trying to connect to existing session..." -ForegroundColor DarkGray
}
$pssession = Get-PSSession -name SfbPowerShell* | Where-Object {$_.Availability -eq 1}
if($pssession.count -eq 0){
    Write-Host "  DEBUG: Could not connect to existing session, starting new session" -ForegroundColor DarkGray
    Connect-MicrosoftTeams
}

Write-Host "  Connected to tenant: " -ForegroundColor White -NoNewLine
Write-Host (Get-CsTenant).DisplayName -ForegroundColor Green


$voiceRoutingPolicies = Get-CsOnlineVoiceRoutingPolicy  | ForEach-Object {($_.Identity -replace "Tag:")}
if($voiceRoutingPolicy -eq $null -or $voiceRoutingPolicy -eq ""){
    Write-Host "================ Please select the Voice Routing Policy ================"

    $i=0
    foreach ($voiceRoutingPolicy in $voiceRoutingPolicies) {
        $i++
        Write-Host "$i : Press $i for $voiceRoutingPolicy"
    }

    $choice = Read-Host "Make a choice"

    if ($choice -gt 0 -and $choice -le $voiceRoutingPolicies.count) {
            $voiceRoutingPolicy = $voiceRoutingPolicies[$choice-1]
            #Write-Host "  Chosen Voice Routing Policy is: " -ForegroundColor White -NoNewline
            #Write-Host "$($voiceRoutingPolicy)" -ForegroundColor Green
        }
    else {
        Write-Host "Invalid selection" -ForegroundColor red
        exit
    }

}
elseif($voiceRoutingPolicy -notin $voiceRoutingPolicies){
    Write-Host "Specified Voice Routing Policy does not exist" -ForegroundColor red
    exit
}


if($debug -like $true){
    Write-Host "  DEBUG: Processing line: $($upn) " -ForegroundColor DarkGray
}
#Correct User
if($upn -notmatch "\@"){
    Write-Host "  WARNING: Not a UPN: "-ForegroundColor yellow -NoNewline
    Write-Host "$($upn)" -ForegroundColor green -NoNewline
    Write-Host ", trying to look up UPN" -ForegroundColor yellow
    $sip = (Get-CsOnlineUser -ErrorAction SilentlyContinue -Identity $($upn)).SipAddress
    if($sip.count -eq 0 ){
        Write-Host "  ERROR: Name not found" -ForegroundColor Red
        exit
    }
    $upn = $sip.TrimStart('sip:')
    Write-Host "  WARNING: Found UPN: "-ForegroundColor yellow -NoNewline
    Write-Host "$($upn)" -ForegroundColor green
}
#Correct Number
if($lineURI -notlike "tel:*"){
    if($lineURI -like "+*"){
        $lineURI = "tel:"+$lineURI
        if($debug -like $true){
            Write-Host "  DEBUG: Added tel:" -ForegroundColor DarkGray
        }
    }
    else{
        $lineURI = "tel:+"+$lineURI
        if($debug -like $true){    
            Write-Host "  DEBUG: Added tel:+" -ForegroundColor DarkGray
        }
    }
}

Write-Host "  Updating user: " -ForegroundColor White -NoNewLine
Write-Host "$($upn)" -ForegroundColor Green -NoNewLine
Write-Host " with " -ForegroundColor White -NoNewLine
Write-Host "$($lineURI)" -ForegroundColor Green -NoNewline
Write-Host " and Voice Policy " -ForegroundColor White -NoNewLine
Write-Host "$($voiceRoutingPolicy)" -ForegroundColor Green


#Check if the number is already assigned to another user
$filterString = 'LineURI -like "{0}"' -f $lineURI
$getLineUri = Get-CsOnlineUser -Filter $filterString | Select-Object DisplayName,UserPrincipalName

if($getLineUri -and $getLineUri.UserPrincipalName -ne $upn){
    Write-Host "  ERROR: Number already assigned to user: " -ForegroundColor Red -NoNewLine
    Write-Host "$($getLineUri.DisplayName)" -ForegroundColor Green -NoNewline
    Write-Host " with UPN " -ForegroundColor Red -NoNewLine
    Write-Host "$($getLineUri.UserPrincipalName)" -ForegroundColor Green
    exit
}

#Enable user and assign phone number
if($debug -like $true){
    Write-Host "  DEBUG: Attempting to set Teams settings: Enabling Telephony Features and Configure Phone Number" -ForegroundColor DarkGray
}
try{
    Set-CsUser -Identity $upn -EnterpriseVoiceEnabled $true -HostedVoiceMail $true -OnPremLineURI $lineURI
}
Catch{
    $errOutput = [PSCustomObject]@{
        status = "failed"
        error = $_.Exception.Message
        step = "SetUser"
        cmdlet = "Set-CsUser"
    }
    Write-Output ( $errOutput | ConvertTo-Json)
    exit
}

#Enable Teams Calling
if($debug -like $true){
    Write-Host "  DEBUG: Attempting to grant Teams settings: TeamsCallingPolicy" -ForegroundColor DarkGray #Policies designate which users are able to use calling functionality within teams and determine the interoperability state with Skype for Business
}
try{
    Grant-CsTeamsCallingPolicy -PolicyName Tag:AllowCalling -Identity $upn
}
Catch{
    $errOutput = [PSCustomObject]@{
        status = "failed"
        error = $_.Exception.Message
        step = "TeamsCallingPolicy"
        cmdlet = "Grant-CsTeamsCallingPolicy"
    }
    Write-Output ( $errOutput | ConvertTo-Json)
    exit
}

#Assign Voice Routing Policy
if($debug -like $true){
    Write-Host "  DEBUG: Attempting to grant Teams settings: Assign the Online Voice Routing Policy" -ForegroundColor DarkGray
}

if($voiceRoutingPolicy -eq "Global"){
    $voiceRoutingPolicy = $null
}

try{
    Grant-CsOnlineVoiceRoutingPolicy -Identity $upn -PolicyName $voiceRoutingPolicy
}
Catch{
    $errOutput = [PSCustomObject]@{
        status = "failed"
        error = $_.Exception.Message
        step = "VoiceRoutingPolicy"
        cmdlet = "Grant-CsOnlineVoiceRoutingPolicy"
    }
    Write-Output ( $errOutput | ConvertTo-Json)
    exit
}

Write-Host "Result:" -ForegroundColor white
Get-CsOnlineUser $upn | Select-Object DisplayName,LineURI,OnlineVoiceRoutingPolicy,EnterpriseVoiceEnabled,HostedVoiceMail,TeamsCallingPolicy,teamsupgrade*
Write-Host "Warning: Voice Routing Policy might take some time to update" -ForegroundColor yellow
#Remove-PSSession $sfboSession