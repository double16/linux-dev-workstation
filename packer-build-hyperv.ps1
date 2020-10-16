Import-Module SmbShare
Import-Module NetTCPIP

$PWD = Get-Location

$RubyInstalled = Test-Path "C:\Ruby24-x64\bin\ruby.exe"
if ($RubyInstalled -eq $false) {
    echo "Ruby 2.4 missing. Install from https://github.com/oneclick/rubyinstaller2/releases/download/rubyinstaller-2.4.5-1/rubyinstaller-devkit-2.4.5-1-x64.exe"
    Exit 1
}

$PackerInstalled = Test-Path ".\packer.exe"
if ($PackerInstalled -eq $false) {
    Invoke-WebRequest -Uri "https://releases.hashicorp.com/packer/1.6.4/packer_1.6.4_windows_amd64.zip" -OutFile "packer.zip"
    Expand-Archive ".\packer.zip" -DestinationPath .
}

.\script\create-natswitch.ps1

$dhcp_ip = Get-NetIPAddress -InterfaceAlias "vEthernet (VagrantSwitch)" | Where-Object {$_.AddressFamily -eq 'IPv4'} | Select -first 1 | foreach { $_.IPAddress }
$dns_ip = Get-DnsClientServerAddress | foreach { $_.ServerAddresses }
Start-Process -FilePath "C:\Ruby24-x64\bin\ruby.exe" -ArgumentList "rdhcpd.rb","$dhcp_ip","$dns_ip" -WindowStyle Hidden

$ShareName = "VagrantCache"
$HostName = Get-NetIPAddress -InterfaceAlias Ethernet | Where-Object {$_.AddressFamily -eq 'IPv4'}  | Select -first 1 | foreach { $_.IPAddress }

$ShareUser = $env:SHARE_USER
if ($null -eq $ShareUser) {
    $ShareUser = Read-Host -Prompt "User for caching share"
}
$SharePassword = $env:SHARE_PASSWORD
if ($null -eq $SharePassword) {
    $SharePassword = Read-Host -assecurestring -Prompt "Password for caching share"
    $SharePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SharePassword))
}

Get-SmbShare -Name $ShareName -OutVariable out -ErrorVariable err -erroraction 'silentlycontinue'
if ("" -ne $out) {
    Remove-SmbShare -Name $ShareName -Force -erroraction 'silentlycontinue'
}

$SharePath = "$PWD\.vagrant\machines\default\cache"
mkdir -Force -p $SharePath
New-SmbShare -Name $ShareName -Path $SharePath -FullAccess $ShareUser -Temporary -ErrorVariable err
if ("" -ne $err) {
  Exit 2
}

.\packer.exe build -only=hyperv-iso -var "packer_host=$HostName" -var "packer_user=$ShareUser" -var "packer_password=$SharePassword" -var-file custom-vars.json packer.json | Tee-Object -FilePath "packer.log"


Remove-SmbShare -Name $ShareName -Force
