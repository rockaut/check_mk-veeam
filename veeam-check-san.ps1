Add-PSSnapin VeeamPSSnapin

$jobs = Get-VBRJob

$jobs | ForEach-Object {
    $currentJob = $_

    $lastSession = Get-VBRTaskSession -Session $currentJob.FindLastSession()
    
    $nbdEntries = $lastSession | where { $_.Logger.GetLog().UpdatedRecords.Title -like "*network mode*" }
    $nbdEntries = $nbdEntries | Sort-Object -Property JobName

    $lineStatus = if( $nbdEntries.Count -gt 0 ) { 1 } else { 0 }
    $lineId     = "veeam_san_" + $currentJob.Name
    $linePerf   = "nbd_count=" + $nbdEntries.Count
    if( $nbdEntries.Count -gt 0 ) {
        $lineNote = "{0} VMs with NBD mode(!): see Details..." -f $nbdEntries.Count
        $nbdEntries | ForEach-Object {
            $lineNote += "\n" + $_.Name
        }
    } else {
        $lineNote = "No NBD modes"
    }
    Write-Host ( "{0} {1} {2} {3}" -f $lineStatus, $lineId, $linePerf, $lineNote )
}
