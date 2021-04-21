    <#
    
    .DESCRIPTION
    Function that can be used to remove files older than a specified age

    .PARAMETER Path
    Specifies the target Path.
    
    .PARAMETER Age
    Specifies the target Age in days, e.g. Last write time of the item.
       
    .EXAMPLE
    .\Remove-OldFiles.ps1 -path d:\CDR -maxFileAge 841
    
    .NOTES

    #>

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$false, Position=0)][string]$path,
  [Parameter(Mandatory=$true, Position=0)][string]$maxFileAge
)

if($path -eq $null -or $path -eq ""){
    #select sourcefile
    Add-Type -AssemblyName System.Windows.Forms
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog

    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
        RootFolder            = "MyComputer"
        Description           = "$Env:ComputerName - Select a folder to clean up"
    }
    $Null = $FolderBrowser.ShowDialog()

    $path = $FolderBrowser.SelectedPath;
    If(-Not $path) {

        Write-Host "No path selected"
        exit
        
    }
}

Write-host "Selected path: " -ForegroundColor white -NoNewline
Write-host $path -ForegroundColor Green

Write-Host "Max File Age: " -ForegroundColor white -NoNewline
Write-host  $maxFileAge -ForegroundColor Green


$confirmation = Read-Host "You are making a distructive action on $path. Are you sure you want to do this? [y/n]"
if ($confirmation -eq 'y') {
        
    Get-ChildItem $path -Recurse -Force -ea 0 | 
    Where-Object {!$_.PsIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-$maxFileAge)} |
    ForEach-Object {
    $_ | del -Force
    $_.FullName | Out-File $PSScriptRoot\deletedlog.txt -Append
    }

}
