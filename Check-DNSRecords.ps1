## PowerShell DNS Checker, This script checks all that you have all your DNS entries in place and displays the final route for DNS lookups.
##
## Usage .\Check-DNSRecords.ps1 <domain> <service> (both optional)
##
## Usage .\Check-DNSRecords.ps1
## Usage .\Check-DNSRecords.ps1 cloud-uc.nl
## Usage .\Check-DNSRecords.ps1 cloud-uc.nl Jabber
## Usage .\Check-DNSRecords.ps1 cloud-uc.nl Skype
## Usage .\Check-DNSRecords.ps1 cloud-uc.nl Video
## Usage .\Check-DNSRecords.ps1 cloud-uc.nl All
##
## By Ruud van Strijp - Axians CS

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true, Position=0)][string]$domain,
  [Parameter(Position=1)][ValidateSet('Jabber','Skype','SkypeOnline','Video','All')][string]$service
)

Write-Host $service

if($service -eq $null -or $service -eq ""){
    Write-Host "================ Please select the service to check DNS records for ================"

    Write-Host "1: Press '1' for Jabber."
    Write-Host "2: Press '2' for Skype."
    Write-Host "3: Press '3' for Skype Online."
    Write-Host "4: Press '4' for Video."
    Write-Host "A: Press 'A' for All of the above."
    Write-Host "Q: Press 'Q' to quit."

    $selectservice = Read-Host "Please make a selection"
    switch ($selectservice)
    {
        '1' {$service = 'Jabber'}
        '2' {$service = 'Skype'}
        '3' {$service = 'SkypeOnline'}
        '4' {$service = 'Video'}
        'a' {$service = 'All'}
        'q' {return}
    }
}

Write-Host "================ Please select the DNS server ================"

Write-Host "1: Press '1' for Google (8.8.8.8)."
Write-Host "2: Press '2' for current computer's default DNS."
Write-Host "Q: Press 'Q' to quit."

$selectserver = Read-Host "Please make a selection"
switch ($selectserver)
{
    '1' {$dnsserver = '8.8.8.8'}
    '2' {$dnsserver = $null}
    'q' {return}
}

function Get-Record{
    param([string]$type = "A",[string]$hostname,[string]$function)
    
    Write-Host "`r`n$function" -ForegroundColor Cyan
   
    $fqdn = $hostname + '.' + $domain

    if ($type -eq 'A'){
        Get-ARecord $fqdn
    }elseif ($type -eq 'SRV'){
        Get-SRVRecord $fqdn
    }

}

function Get-ARecord{
    param([string]$fqdn)

    $dnsresult = Resolve-DnsName $fqdn -Server $dnsserver -ErrorAction SilentlyContinue | Where-Object {$_.Type -eq 'A' -or $_.Type -eq 'CNAME'}

    if ($dnsresult) { 
        foreach ($result in $dnsresult | Where-Object {$_.Name -eq $fqdn} ){

            $resultType = $result.Type
            if ($resultType -eq 'A') {
                #result is A-Record
                $resultIP = $result.IPAddress
                Write-Host "`t$resultType : $fqdn ($resultIP)" -ForegroundColor Green
            } else {
                #result is CNAME
                $resultNameHost = $result.NameHost
                Write-Host "`t$resultType : $fqdn ($resultNameHost)" -ForegroundColor Green
                Get-ARecord $resultNameHost
            }
  
        }
    } else { 
        Write-Host "`tDNS Entry Not Found" -ForegroundColor Red
    }
}

function Get-CNAMERecord{
        Write-Host "`tCNAME" -ForegroundColor Red

}

function Get-SRVRecord{
    param([string]$fqdn)

    $dnsresult = Resolve-DnsName $fqdn -Type SRV -Server $dnsserver -ErrorAction SilentlyContinue

    if ($dnsresult.Name -eq $fqdn) { 
 
        foreach ($result in $dnsresult | Where-Object {$_.Name -eq $fqdn} ){
            $nametarget = $result.NameTarget
            $priority = $result.Priority
            $weight = $result.Weight
            $port = $result.Port

            Write-Host "`t$fqdn -> $nametarget : $port   P:$priority W:$weight" -ForegroundColor Green
            Get-ARecord $nametarget

        }

    } else { 
        Write-Host "`tDNS Entry Not Found" -ForegroundColor Red
    }
}

if($service -eq 'Skype' -or $service -eq 'All'){
    Get-Record -type 'A' -hostname 'sip' -function 'SIP A / CNAME'
    Get-Record -type 'A' -hostname 'sipexternal' -function 'SIP External A / CNAME'
    Get-Record -type 'A' -hostname 'sipinternal' -function 'SIP Internal A / CNAME'
    Get-Record -type 'A' -hostname 'lyncdiscover' -function 'Lyncdiscover A / CNAME'
    Get-Record -type 'A' -hostname 'lyncdiscoverinternal' -function 'Lyncdiscover internal A / CNAME'
    Get-Record -type 'SRV' -hostname '_sipfederationtls._tcp' -function 'Federation SRV'
    Get-Record -type 'SRV' -hostname '_sip._tls' -function 'SIP TLS SRV'
    Get-Record -type 'SRV' -hostname '_sipinternaltls._tcp' -function 'SIP Internal TLS SRV'
}
if($service -eq 'SkypeOnline' -or $service -eq 'All'){
    Get-Record -type 'A' -hostname 'sip' -function 'SIP A / CNAME'
    Get-Record -type 'A' -hostname 'lyncdiscover' -function 'Lyncdiscover A / CNAME'
    Get-Record -type 'SRV' -hostname '_sipfederationtls._tcp' -function 'Federation SRV'
    Get-Record -type 'SRV' -hostname '_sip._tls' -function 'SIP TLS SRV'
}
if($service -eq 'Jabber' -or $service -eq 'All'){
    Get-Record -type 'SRV' -hostname '_collab-edge._tls' -function 'Collab Edge SRV'
    Get-Record -type 'SRV' -hostname '_cisco-uds._tcp' -function 'Cisco-UDS SRV'
    Get-Record -type 'A' -hostname 'collab-edge' -function 'Collab Edge A'
}
if($service -eq 'Video' -or $service -eq 'All'){
    Get-Record -type 'SRV' -hostname '_sip._tcp' -function 'SIP TCP SRV'
    Get-Record -type 'SRV' -hostname '_sip._udp' -function 'SIP UDP SRV'
    Get-Record -type 'SRV' -hostname '_sips._tcp' -function 'SIPS TCP SRV'
    Get-Record -type 'SRV' -hostname '_h323cs._tcp' -function 'H323CS TCP SRV'
    Get-Record -type 'SRV' -hostname '_h323ls._udp' -function 'H323LS UDP SRV'
}
pause
