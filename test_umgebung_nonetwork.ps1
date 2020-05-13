# funktion to create a Windows Server 2016 vm from a generalized master vhdx
# syntax create_server 
cls 
$global:server_name=""
$global:client_name=""
function create_server {
    param ( 
      [string]$global:server_name = $(Read-Host "1. VM Name (z.B. DC_Uebung_A) default: SLAP_Uebung_DC"),
      [System.Int64]$vmram = $(Read-Host "Wieviele Gb RAM (z.B 2 für 2Gb usw.) default ist 2Gb")
    )
if ([String]::IsNullOrEmpty($global:server_name)) { $global:server_name = "SLAP_Uebung_DC" }
if ($vmram -eq "") { [System.Int64]$vmram = 2 }

# create a home directory for the vm
Write-Host "Erstellen VM Home Ordner und kopieren Master-Image..."
$current_dir = (Get-Location).Path
New-Item -Path "$current_dir\VMs\" -Name "$global:server_name" -ItemType "directory"|Out-Null 

# copying master to vm's home
Copy-Item $current_dir\masters\win_server16_14393_de_master.vhdx -Destination $current_dir\VMs\$global:server_name

# creating a new vm 
Write-Host "Aufsetzen den Domaincontroller..."

new-vm `
-Name $global:server_name `
-MemoryStartupBytes ($vmram * 1GB) `
-Generation 2 `
-VHDPath $current_dir\VMs\$global:server_name\win_server16_14393_de_master.vhdx `
-SwitchName "Default Switch" `

Write-host "Domaincontroller erstellt"
# setting bootorder
$bootorder = Get-VMFirmware -VMName $global:server_name
$hdddrive = $bootorder.BootOrder[0]
$pxe = $bootorder.BootOrder[1]
Set-VMFirmware -VMName $global:server_name -BootOrder $hdddrive,$pxe

# setting VM resolution (not working)
Set-VMVideo -VMName $global:server_name -ResolutionType Default -HorizontalResolution 1024 -VerticalResolution 768

# setting up additional network interface (creating if necessary)

if (((Get-VMSwitch).SwitchType -contains "Private") -eq $false) {
  Write-Host "Du hast noch keine PrivateSwitch..."
  sleep 5
  New-VMSwitch -name PrivateSwitch -SwitchType Private -InformationAction SilentlyContinue|Out-Null
  Write-Host "Virtuelle PrivateSwitch erstellt"
  sleep5 
}
Add-VMNetworkAdapter -VMName $global:server_name -SwitchName PrivateSwitch

# starting vm
Write-host "$global:server_name starten..."
Start-VM -VMName $global:server_name|out-null
Write-host "$global:server_name gestartet"

}

#########################################################################################################################

function create_client {
    param ( 
      [string]$global:client_name = $(Read-Host "2. VM Name (z.B. DC_Uebung_A) default: SLAP_Uebung_WinClient"),
      [System.Int64]$vmram = $(Read-Host "Wieviele Gb RAM (z.B 2 für 2Gb usw.) default ist 2Gb")
    )
if ([String]::IsNullOrEmpty($global:client_name)) { $global:client_name = "SLAP_Uebung_WinClient" }
if ($vmram -eq "") { [System.Int64]$vmram = 2 }

# create a home directory for the vm
Write-Host "Erstellen VM Home Ordner und kopieren Master-Image..."
$current_dir = (Get-Location).Path
New-Item -Path "$current_dir\VMs\" -Name "$global:client_name" -ItemType "directory"|Out-Null 

# copying master to vm's home
Copy-Item $current_dir\masters\win10_client_15063_de_master.vhdx -Destination $current_dir\VMs\$global:client_name

# creating a new vm 
Write-Host "Aufsetzen den Client-Computer..."

new-vm `
-Name $global:client_name `
-MemoryStartupBytes ($vmram * 1GB) `
-Generation 2 `
-VHDPath $current_dir\VMs\$global:client_name\win10_client_15063_de_master.vhdx `
-SwitchName "PrivateSwitch" `


Write-host "$global:client_name erstellt"

# setting bootorder
$bootorder = Get-VMFirmware -VMName $global:client_name
$hdddrive = $bootorder.BootOrder[0]
$pxe = $bootorder.BootOrder[1]
Set-VMFirmware -VMName $global:client_name -BootOrder $hdddrive,$pxe


# setting up network interface (creating if necessary)
#Add-VMNetworkAdapter -VMName $global:client_name -SwitchName PrivateSwitch

# starting vm
Write-host "$global:client_name starten..."
Start-VM -VMName $global:client_name|out-null
Write-host "$global:client_name gestartet"

}
#####################################################################################################################

# reading credentials
$username = "administrator"
$password = ConvertTo-SecureString "123user!" -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

# Server VM booting to desktop 
create_server 

# checking vm status

write-host "Prüfen $global:server_name status:"
while ( (get-vm -vmname $global:server_name).Heartbeat -notlike 'Ok*') {
write-host "Booting $global:server_name ... Status: $((get-vm -vmname $global:server_name).Heartbeat)"
sleep 10
}
write-host "$global:server_name ist online! juhhuu :)    Status: $((get-vm -vmname $global:server_name).Heartbeat)"
# creating Client vm
create_client

# checking vm status
write-host "Prüfen $global:client_name status:"
while ( (get-vm -vmname $global:client_name).Heartbeat -notlike 'Ok*') {
  write-host "Booting $global:client_name ... Status: $((get-vm -vmname $global:client_name).Heartbeat)"
sleep 10
}
write-host "$global:client_name ist online! juhhuu :)    Status: $((get-vm -vmname $global:client_name).Heartbeat)"

 write-host "$global:server_name ist fertig und gestartet" write-host "$global:client_name ist fertig und gestartet" write-host "Username: administrator" write-host "Password: 123user!"