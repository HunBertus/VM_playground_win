function create_vm {
    param ( [string]$name )
$current_dir = (Get-Location).Path
new-vm -Name $name -MemoryStartupBytes 4Gb -Generation 2 `
-NewVHDPath $current_dir\$name.vhdx -NewVHDSizeBytes 25Gb `
-SwitchName Privat01
Add-VMDvdDrive -VMName $name
$bootorder = Get-VMFirmware -VMName $name
$hdddrive = $bootorder.BootOrder[0]
$pxe = $bootorder.BootOrder[1]
$dvddrive = $bootorder.BootOrder[2]
Set-VMFirmware -VMName $name -BootOrder $dvddrive,$hdddrive,$pxe
}

# 1. VM
create_vm -name unattended_master_image_de
Set-VMDvdDrive -VMName unattended_master_image_de -Path C:\ISO_files\17763.1.180914-1434.rs5_release_SERVER_EVAL_x64FRE_de-de.iso