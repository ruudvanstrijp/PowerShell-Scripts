<#
.SYNOPSIS

Script to quickly update current Skype pool's SQL database
I always have to search which Skype pool uses which SQL server in my lab. This helps with that.
Not extensively tested; use at your own risk

.NOTES

.EXAMPLE

#>

$computerFQDN = "$env:computername.$env:userdnsdomain".ToLower()
$skypePoolFQDN = (Get-CsPool).where({$_.computers -like "*$computerFQDN*" }).fqdn

if ($skypePoolFQDN -eq $null -or $skypePoolFQDN -eq ""){
	Write-Host "Current server doesn't seem to be part of a Skype pool" -ForegroundColor red
	exit
}

Write-Host "  Skype Pool FQDN: "-ForegroundColor white -NoNewline
Write-Host "$($skypePoolFQDN)" -ForegroundColor green

$sqlPoolFQDN = (Get-CsService -ApplicationDatabase).where({$_.DependentServiceList -like "*$skypePoolFQDN*" }).PoolFqdn

if ($sqlPoolFQDN -eq $null -or $sqlPoolFQDN -eq ""){
	Write-Host "Can't find SQL pool" -ForegroundColor red
	exit
}

Write-Host "  SQL Pool FQDN: "-ForegroundColor white -NoNewline
Write-Host "$($sqlPoolFQDN)" -ForegroundColor green

$confirmation = Read-Host "Do you want to update the SQL Database? [y/n]"
if ($confirmation -eq 'y') {
	Install-CsDatabase -Update -ConfiguredDatabases -SqlServerFqdn $sqlPoolFQDN
}