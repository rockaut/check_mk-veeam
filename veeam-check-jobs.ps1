Add-PSSnapin VeeamPSSnapin

$jobs = Get-VBRJob

$jobs | ForEach-Object {
    $currentJob = $_
    $lastSession = $currentJob.FindLastSession()

    ## WillBeRetries not Error
    ## IsManuallyStopped is Warning

    if( $lastSession.IsCompleted -eq $true ) {
        $lineStatus = 0
        $lineNote = "State: {0}" -f $lastSession.State
        $duration = $lastSession.EndTime - $lastSession.CreationTime
        $lineNote = "{0} - {1}" -f $lineNote, ( "Duration {0:hh}:{0:mm}:{0:ss}" -f $duration )  
             
        $linePerf = "BaseProgress=0"
        $linePerf += " Duration=0"
        $linePerf += " Duration={0}" -f $duration.TotalSeconds
        $linePerf += " BackupSize={0}" -f $lastSession.BackupStats.BackupSize
        $linePerf += " DataSize={0}" -f $lastSession.BackupStats.DataSize
        $linePerf += " DedupRatio={0}" -f $lastSession.BackupStats.DedupRatio
        $linePerf += " CompressRatio={0}" -f $lastSession.BackupStats.CompressRatio
    } else {
        $lineStatus = 0
        $lineNote = "State: {0} @ {1}%" -f $lastSession.State, $lastSession.BaseProgress
        $duration = (Get-Date) - $lastSession.CreationTime
        $lineNote = "{0} - {1}" -f $lineNote, ( "Duration {0:hh}:{0:mm}:{0:ss}" -f $duration )
        
        $linePerf = "BaseProgress={0}" -f $lastSession.BaseProgress
        $linePerf += " BackupSize=0"
        $linePerf += " DataSize=0"
        $linePerf += " DedupRatio=0"
        $linePerf += " CompressRatio=0"
    }

    $lineNote = $lastSession.Result.ToString() + " - " + $lineNote
    if( $lastSession.Result -ne "Success" ) {
        if( $lastSession.Result -eq "Failed" ) {
            $lineStatus = 2
        }
        elseif( $lastSession.Result -eq "Warning" ) {
            $lineStatus = 1
        }
    } else {
        $lineStatus = 0
    }    
    
    $lineId     = "veeam_job_" + $currentJob.Name
    $linePerf   = "{0}" -f $linePerf
    $lineNote = "{0} - see Details..." -f $lineNote

    Write-Host ( "{0} {1} {2} {3}" -f $lineStatus, $lineId, $linePerf, $lineNote )
}
