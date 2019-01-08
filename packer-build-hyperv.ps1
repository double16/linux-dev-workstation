Import-Module SmbShare
Import-Module NetTCPIP

.\script\create-natswitch.ps1

$ShareName = "VagrantCache"
$HostName = Get-NetIPAddress -InterfaceAlias Ethernet0 | foreach { $_.IPAddress }
$ShareUser = Read-Host -Prompt "User for caching share"
$SharePassword = Read-Host -assecurestring -Prompt "Password for caching share"
$SharePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SharePassword))

Get-SmbShare -Name $ShareName -OutVariable out -ErrorVariable err -erroraction 'silentlycontinue'
if ("" -ne $out) {
    Remove-SmbShare -Name $ShareName -Force -erroraction 'silentlycontinue'
}

New-SmbShare -Name $ShareName -Path C:\Users\req86053\workspace\linux-dev-workstation\packer_cache -FullAccess $ShareUser -Temporary -ErrorVariable err
if ("" -ne $err) {
  Exit
}

..\packer.exe build -only=hyperv-iso -var "packer_host=$HostName" -var "packer_user=$ShareUser" -var "packer_password=$SharePassword" -var-file mutual.json centos.json | Tee-Object -FilePath "packer.log"


Remove-SmbShare -Name $ShareName -Force
