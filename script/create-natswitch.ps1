# From https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/setup-nat-network

$current = $null
$current = Get-VMSwitch -SwitchName "VagrantSwitch"
if ($null -eq $current) {
    New-VMSwitch -SwitchName "VagrantSwitch" -SwitchType Internal
}
$IFINDEX = Get-NetAdapter "vEthernet (VagrantSwitch)" | foreach { $_.ifIndex }

$current = $null
$current = Get-NetIPAddress -IPAddress 192.168.0.1
if ($null -eq $current) {
    New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $IFINDEX
}

$current = $null
$current = Get-NetNat -Name VagrantNATnetwork
if ($null -eq $current) {
  New-NetNat -Name VagrantNATnetwork -InternalIPInterfaceAddressPrefix 192.168.0.0/24
}
