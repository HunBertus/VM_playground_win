# funktion to make a vm from a generalized master vhdx
# syntax create_vm <vmname>

function create_vm {
    param ( [string]$vmname )

# create a home directory for the vm
$current_dir = (Get-Location).Path
New-Item -Path "$current_dir\VMs\" -Name "$vmname" -ItemType "directory"

# copying master to vm's home
Copy-Item C:\Hyper-V\master_image_de.vhdx -Destination $current_dir\VMs\$vmname

# creating a new vm (maybe later could be parametrized ram, generation, etc)
new-vm `
-Name $vmname `
-MemoryStartupBytes 4Gb `
-Generation 2 `
-VHDPath $current_dir\VMs\$vmname\master_image_de.vhdx `
-SwitchName "Default Switch"

# setting bootorder
$bootorder = Get-VMFirmware -VMName $vmname
$hdddrive = $bootorder.BootOrder[0]
$pxe = $bootorder.BootOrder[1]
Set-VMFirmware -VMName $vmname -BootOrder $hdddrive,$pxe

# setting VM resolution
Set-VMVideo -VMName $vmname -ResolutionType Default -HorizontalResolution 1024 -VerticalResolution 768

#setting up additional network interface
Add-VMNetworkAdapter -VMName $vmname -SwitchName Privat01

# starting vm
Start-VM -VMName $vmname

}
# reading credentials
$username = "administrator"
$password = ConvertTo-SecureString "123user!" -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

# 1. VM booting to desktop 
create_vm testvm1

# checking vm status

while ( (get-vm -vmname testvm1).Heartbeat -notlike 'Ok*') {
(get-vm -vmname testvm1).Heartbeat
sleep 10
}
(get-vm -vmname testvm1).Heartbeat

# configurating vm network

# renaming interfaces
 #$LANinterface = Invoke-Command -VMName testvm1 -Credential $cred -ScriptBlock `
 #{ #(Get-NetIPAddress -AddressFamily IPv4|? {$_.IPAddress -like '169.254*'}).InterfaceAlias ` #} #$WANinterface = Invoke-Command -VMName testvm1 -Credential $cred -ScriptBlock `
 #{ #(Get-NetIPAddress -AddressFamily IPv4|? {$_.IPAddress -like '192.168.*'}).InterfaceAlias ` #} Invoke-Command -VMName testvm1 -Credential $cred -ScriptBlock { Rename-NetAdapter -Name "Ethernet 3" -NewName "LAN"} Invoke-Command -VMName testvm1 -Credential $cred -ScriptBlock { Rename-NetAdapter -Name "Ethernet 2" -NewName "WAN"}  # setting network config for LAN Invoke-Command -VMName testvm1 -Credential $cred -ScriptBlock {  New-NetIPAddress -InterfaceAlias LAN -AddressFamily IPv4 -IPAddress 192.168.0.1 -PrefixLength 24} Invoke-Command -VMName testvm1 -Credential $cred -ScriptBlock {  Set-DnsClientServerAddress -interfacealias LAN -serveraddresses 192.168.0.1  } # setting Datei und Druckerfreigabe activated:
 Set-NetFirewallRule -DisplayGroup "Datei- und Druckerfreigabe" -Enabled True -Profile Private #installing ad features