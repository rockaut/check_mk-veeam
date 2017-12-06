$wmiDesc = Get-WmiObject -Namespace root\wmi -Class MPIO_GET_DESCRIPTOR
$wmiDisk = Get-WmiObject -Namespace root\wmi -Class MPIO_DISK_INFO
$wmiDiskHI = Get-WmiObject -Namespace root\wmi -Class MPIO_DISK_HEALTH_INFO

Write-Host "<<<local>>>"
$wmiDisk.DriveInfo | ForEach-Object {
    $diskID       = $_.Name.Replace(" ", "-")
    $diskDeviceName = "\Device\" + $_.Name.Replace(" ", "")
    $diskName     = $_.Name
    $diskNumPaths = $_.NumberPaths
    $diskSerial   = $_.SerialNumber

    $desc = $wmiDesc | where { $_.DeviceName -eq $diskDeviceName }
    $health = $wmiDiskHI.DiskHealthPackets | where { $_.Name -eq $diskName }

    $luns = $desc.PdoInformation.ScsiAddress.Lun | Select-Object -Unique

    $checkState   = 0
    $checkNotes   = ("Name: {0} - Lun(s): {1}" -f $diskName, $luns)
    $checkId      = "mpio_state_{0}" -f $diskSerial
    $checkPerfs   = ("diskNumPaths={0}" -f $diskNumPaths)
    $checkPerfs   += ("|NumberBytesRead={0}" -f $health.NumberBytesRead)
    $checkPerfs   += ("|NumberBytesWritten={0}" -f $health.NumberBytesWritten)
    $checkPerfs   += ("|NumberIoErrors={0}" -f $health.NumberIoErrors)
    $checkPerfs   += ("|NumberReads={0}" -f $health.NumberReads)
    $checkPerfs   += ("|NumberRetries={0}" -f $health.NumberRetries)
    $checkPerfs   += ("|NumberWrites={0}" -f $health.NumberWrites)

    if($health.DeviceOffline -eq $true) {
        $checkState = [math]::Max(2, $checkState)
        $checkNotes += (" - {0}" -f "DEVICE OFFLINE (!!)" )
    }
    if($health.PathFailures -gt 0) {
        $checkState = [math]::Max(2, $checkState)
        $checkNotes += (" - {1} {0} - Failed at {2}" -f "Path Failures (!!)", $health.PathFailures, $health.FailTime )
    }

    $checkNotes   = ("Name: {0} - Lun(s): {1}" -f $diskName, $luns)

    Write-Host ("{0} {1} {2} {3}" -f $checkState, $checkId, $checkPerfs, $checkNotes)
}
