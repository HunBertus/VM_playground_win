# funktion to make a vm from a generalized master vhdx
# syntax create_vm <vmname>

function create_vm {
    param ( [string]$vmname )

# create a home directory for the vm
New-Item -Path "C:\Hyper-V\" -Name "$vmname" -ItemType "directory"

# copying master to vm's home
Copy-Item C:\Hyper-V\master_image_de.vhdx -Destination C:\Hyper-V\$vmname

# creating a new vm (maybe later could be parametrized ram, generation, etc)
new-vm `
-Name $vmname `
-MemoryStartupBytes 4Gb `
-Generation 2 `
-VHDPath C:\Hyper-V\$vmname\master_image_de.vhdx `
-SwitchName "Default Switch"

# setting bootorder
$bootorder = Get-VMFirmware -VMName $vmname
$hdddrive = $bootorder.BootOrder[0]
$pxe = $bootorder.BootOrder[1]
Set-VMFirmware -VMName $vmname -BootOrder $hdddrive,$pxe

# starting vm
Start-VM -VMName $vmname
}
# reading credentials
$username = "administrator"
$password = ConvertTo-SecureString "123user!" -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

# 1. VM
create_vm testvm1
