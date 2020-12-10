
$filter = "Web*"
$certlist = New-Object -TypeName System.Collections.ArrayList
$certs = certutil -template | Select-String -Pattern TemplatePropCommonName

foreach ($cert in $certs) {
      $certname = $cert -Split(" = ")
      $certlist.Add($certname[1]) > $null
}

$certlistfiltered = @($certlist) -match $filter

Write-Host "================ Please select the certificate template ================"

$i=0
foreach ($certtype in $certlistfiltered) {
    $i++
    Write-Host "$i : Press $i for $certtype"
}

$choice = Read-Host "Make a choice"

if ($choice -gt 0 -and $choice -le $certlistfiltered.count) {
        $selectedcert = $certlistfiltered[$choice-1]
        Write-Host "Chosen certificate is:" $selectedcert
    }
    else {
        Write-Host "Invalid selection"
        exit
    }



#select sourcefile
Add-Type -AssemblyName System.Windows.Forms
$FileBrowserSource = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Multiselect = $false # Multiple files can be chosen
    InitialDirectory = [Environment]::GetFolderPath('Desktop')
}
    
[void]$FileBrowserSource.ShowDialog()

$sourcefile = $FileBrowserSource.FileName;
If(-Not $sourcefile) {

    Write-Host "No sourcefile selected"
    exit
    
}

Write-host "Selected source file: " $sourcefile

#select destination file
Add-Type -AssemblyName System.Windows.Forms
$FileBrowserDestination = New-Object System.Windows.Forms.SaveFileDialog -Property @{
    Multiselect = $false # Multiple files can be chosen
}
[void]$FileBrowserDestination.ShowDialog()

$destinationfile = $FileBrowserDestination.FileName;
If(-Not $destinationfile) {

    Write-Host "No destination file selected"
    exit
    
}

Write-host "Selected destination file: " $destinationfile

Write-Host "Certreq command: certreq -attrib "CertificateTemplate:"$selectedcert -submit $sourcefile $destinationfile"

Invoke-Expression -Command "certreq -attrib CertificateTemplate:$selectedcert -submit $sourcefile $destinationfile"