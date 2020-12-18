<#
Based on UCDialPlans.com
https://www.ucdialplans.com

Stripped and modified by Ruud van Strijp - Axians

#Usage
This script assumes a SFB Online connection is already made. This can be made using my script Connect-TeamsSkypeOnline.ps1

#>

# $ErrorActionPreference can be set to SilentlyContinue, Continue, Stop, or Inquire for troubleshooting purposes
$Error.Clear()
$ErrorActionPreference = 'SilentlyContinue'

$DPParent = "Global"

Write-Host "Creating normalization rules"
$NR = @()
$NR += New-CsVoiceNormalizationRule -Name 'NL-Gratis' -Parent $DPParent -Pattern '^0(800\d{4,7})\d*$' -Translation '+31$1' -InMemory
$NR += New-CsVoiceNormalizationRule -Name 'NL-Premium' -Parent $DPParent -Pattern '^0(90\d{5,8}|8[47]\d{7})$' -Translation '+31$1' -InMemory
$NR += New-CsVoiceNormalizationRule -Name 'NL-Mobiel' -Parent $DPParent -Pattern '^0((6\d{8}))$' -Translation '+31$1' -InMemory
$NR += New-CsVoiceNormalizationRule -Name 'NL-Nationaal' -Parent $DPParent -Pattern '^0(([1-57]\d{4,8}|8[58]\d{7}))\d*(\D+\d+)?$' -Translation '+31$1' -InMemory
$NR += New-CsVoiceNormalizationRule -Name 'NL-Service' -Parent $DPParent -Pattern '^(112|144|140\d{2,3}|116\d{3}|18\d{2})$' -Translation '$1' -InMemory
$NR += New-CsVoiceNormalizationRule -Name 'NL-Internationaal' -Parent $DPParent -Pattern '^(?:\+|00)(1|7|2[07]|3[0-46]|39\d|4[013-9]|5[1-8]|6[0-6]|8[1246]|9[0-58]|2[1235689]\d|24[013-9]|242\d|3[578]\d|42\d|5[09]\d|6[789]\d|8[035789]\d|9[679]\d)(?:0)?(\d{6,14})(\D+\d+)?$' -Translation '+$1$2' -InMemory

Set-CsTenantDialPlan -Identity $DPParent -NormalizationRules @{add=$NR}


Write-Host 'Creating voice policies'
New-CsOnlineVoiceRoutingPolicy "NL-Nationaal" -WarningAction:SilentlyContinue | Out-Null
New-CsOnlineVoiceRoutingPolicy "NL-Internationaal" -WarningAction:SilentlyContinue | Out-Null


Write-Host 'Creating PSTN usages'
Set-CsOnlinePSTNUsage -Identity global -Usage @{Add="NL-Service"} -WarningAction:SilentlyContinue | Out-Null
Set-CsOnlinePSTNUsage -Identity global -Usage @{Add="NL-Nationaal"} -WarningAction:SilentlyContinue | Out-Null
Set-CsOnlinePSTNUsage -Identity global -Usage @{Add="NL-Mobiel"} -WarningAction:SilentlyContinue | Out-Null
Set-CsOnlinePSTNUsage -Identity global -Usage @{Add="NL-Premium"} -WarningAction:SilentlyContinue | Out-Null
Set-CsOnlinePSTNUsage -Identity global -Usage @{Add="NL-Internationaal"} -WarningAction:SilentlyContinue | Out-Null


Write-Host "Adding PSTN usages to voice routing policies"
Set-CsOnlineVoiceRoutingPolicy -Identity "NL-Nationaal" -OnlinePstnUsages @{Add="NL-Service"} | Out-Null
Set-CsOnlineVoiceRoutingPolicy -Identity "NL-Nationaal" -OnlinePstnUsages @{Add="NL-Nationaal"} | Out-Null
Set-CsOnlineVoiceRoutingPolicy -Identity "NL-Nationaal" -OnlinePstnUsages @{Add="NL-Mobiel"} | Out-Null

Set-CsOnlineVoiceRoutingPolicy -Identity "NL-Internationaal" -OnlinePstnUsages @{Add="NL-Service"} | Out-Null
Set-CsOnlineVoiceRoutingPolicy -Identity "NL-Internationaal" -OnlinePstnUsages @{Add="NL-Nationaal"} | Out-Null
Set-CsOnlineVoiceRoutingPolicy -Identity "NL-Internationaal" -OnlinePstnUsages @{Add="NL-Mobiel"} | Out-Null
Set-CsOnlineVoiceRoutingPolicy -Identity "NL-Internationaal" -OnlinePstnUsages @{Add="NL-Premium"} | Out-Null
Set-CsOnlineVoiceRoutingPolicy -Identity "NL-Internationaal" -OnlinePstnUsages @{Add="NL-Internationaal"} | Out-Null


# Check for existence of PSTN gateways and prompt to add PSTN usages/routes

$PSTNGW = Get-CsOnlinePSTNGateway
If (($PSTNGW.Identity -eq $null) -and ($PSTNGW.Count -eq 0)) {
    Write-Host
    Write-Host 'No PSTN gateway found. If you want to configure Direct Routing, you have to define at least one PSTN gateway Using the New-CsOnlinePSTNGateway command.' -ForegroundColor Yellow
    Exit
}

If ($PSTNGW.Count -gt 1) {
    $PSTNGWList = @()
    Write-Host
    Write-Host "ID    PSTN Gateway"
    Write-Host "==    ============"
    For ($i=0; $i -lt $PSTNGW.Count; $i++) {
        $a = $i + 1
        Write-Host ($a, $PSTNGW[$i].Identity) -Separator "     "
    }

    $Range = '(1-' + $PSTNGW.Count + ')'
    Write-Host
    $Select = Read-Host "Select a primary PSTN gateway to apply routes" $Range

    If (($Select -gt $PSTNGW.Count) -or ($Select -lt 1)) {
        Write-Host 'Invalid selection' -ForegroundColor Red
        Exit
    }
    Else {
        $PSTNGWList += $PSTNGW[$Select-1]
    }

    $Select = Read-Host "OPTIONAL - Select a secondary PSTN gateway to apply routes (or 0 to skip)" $Range

    If (($Select -gt $PSTNGW.Count) -or ($Select -lt 0)) {
        Write-Host 'Invalid selection' -ForegroundColor Red
        Exit
    }
    ElseIf ($Select -gt 0) {
        $PSTNGWList += $PSTNGW[$Select-1]
    }
}
Else { # There is only one PSTN gateway
    $PSTNGWList = Get-CSOnlinePSTNGateway
}



Write-Host "Creating voice routes"
New-CsOnlineVoiceRoute -Name "NL-Mobiel" -Priority 2 -OnlinePstnUsages "NL-Mobiel" -OnlinePstnGatewayList $PSTNGWList.Identity -NumberPattern '^\+31(6\d{8})$' | Out-Null
New-CsOnlineVoiceRoute -Name "NL-Gratis" -Priority 3 -OnlinePstnUsages "NL-Lokaal" -OnlinePstnGatewayList $PSTNGWList.Identity -NumberPattern '^\+31800\d{4,7}$' | Out-Null
New-CsOnlineVoiceRoute -Name "NL-Premium" -Priority 4 -OnlinePstnUsages "NL-Premium" -OnlinePstnGatewayList $PSTNGWList.Identity -NumberPattern '^\+3190\d{5,8}|8[47]\d{7}$' | Out-Null
New-CsOnlineVoiceRoute -Name "NL-Nationaal" -Priority 5 -OnlinePstnUsages "NL-Nationaal" -OnlinePstnGatewayList $PSTNGWList.Identity -NumberPattern '^\+310?([1-57]\d{4,8}|8[58]\d{7})' | Out-Null
New-CsOnlineVoiceRoute -Name "NL-Internationaal" -Priority 7 -OnlinePstnUsages "NL-Internationaal" -OnlinePstnGatewayList $PSTNGWList.Identity -NumberPattern '^\+((1[2-9]\d\d[2-9]\d{6})|((?!(31))([2-9]\d{6,14})))' | Out-Null
New-CsOnlineVoiceRoute -Name "NL-Service" -Priority 6 -OnlinePstnUsages "NL-Service" -OnlinePstnGatewayList $PSTNGWList.Identity -NumberPattern '^\+?(112|144|140\d{2,3}|116\d{3}|18\d{2})$' | Out-Null

Write-Host 'Creating outbound translation rules'
$OutboundTeamsNumberTranslations = New-Object 'System.Collections.Generic.List[string]'
New-CsTeamsTranslationRule -Identity "NL-TeamsTranslationRule" -Pattern '^\+(1|7|2[07]|3[0-46]|39\d|4[013-9]|5[1-8]|6[0-6]|8[1246]|9[0-58]|2[1235689]\d|24[013-9]|242\d|3[578]\d|42\d|5[09]\d|6[789]\d|8[035789]\d|9[679]\d)(?:0)?(\d{6,14})(;ext=\d+)?$' -Translation '+$1$2' | Out-Null
$OutboundTeamsNumberTranslations.Add("NL-TeamsTranslationRule")

Write-Host 'Adding translation rules to PSTN gateways'
ForEach ($PSTNGW in $PSTNGWList) {
	Set-CsOnlinePSTNGateway -Identity $PSTNGW.Identity -OutboundTeamsNumberTranslationRules $OutboundTeamsNumberTranslations -ErrorAction SilentlyContinue
}