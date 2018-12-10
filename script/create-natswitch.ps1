# From https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/setup-nat-network
New-VMSwitch -SwitchName "VagrantSwitch" -SwitchType Internal
IFINDEX=$(Get-NetAdapter "vEthernet (VagrantSwitch)" | foreach { $_.ifIndex })
New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $IFINDEX
New-NetNat -Name VagrantNATnetwork -InternalIPInterfaceAddressPrefix 192.168.0.0/24
