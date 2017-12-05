Add-PSSnapin VeeamPSSnapin

$jobMaxDurationMinutes = @{
    0 = 900; #Sunday
    1 = 240; 
    2 = 240;
    3 = 240;
    4 = 240;
    5 = 240;
    6 = 900; #Saturday
}

$jobs = Get-VBRJob

$jobs | ForEach-Object {
    $currentJob = $_
    $lastSession = $currentJob.FindLastSession()

    ## WillBeRetries not Error
    ## IsManuallyStopped is Warning
    ## MaxDuration on Day 0-6

    $lineStatus = 0

    if( $lastSession.IsCompleted -eq $true ) {
        $lineStatus = [math]::Max(0, $lineStatus)
        $lineNote = "State: {0}" -f $lastSession.State
        $duration = $lastSession.EndTime - $lastSession.CreationTime

        $linePerf = "BaseProgress=0"
        $linePerf += "|Duration=0"
        $linePerf += "|Duration={0}" -f $duration.TotalSeconds
        $linePerf += "|BackupSize={0}" -f $lastSession.BackupStats.BackupSize
        $linePerf += "|DataSize={0}" -f $lastSession.BackupStats.DataSize
        $linePerf += "|DedupRatio={0}" -f $lastSession.BackupStats.DedupRatio
        $linePerf += "|CompressRatio={0}" -f $lastSession.BackupStats.CompressRatio
    } else {
        $lineStatus = [math]::Max(0, $lineStatus)
        $lineNote = "State: {0} @ {1} &#37;" -f $lastSession.State, $lastSession.BaseProgress
        $duration = (Get-Date) - $lastSession.CreationTime
        
        $linePerf = "BaseProgress={0}" -f $lastSession.BaseProgress
        $linePerf += "|BackupSize=0"
        $linePerf += "|DataSize=0"
        $linePerf += "|DedupRatio=0"
        $linePerf += "|CompressRatio=0"
    }

    if( $duration.TotalMinutes -gt $jobMaxDurationMinutes[[int]((get-date).DayOfWeek)] ) {
        $lineStatus = [math]::Max(1, $lineStatus)
        $lineNote = "{0} - {1}" -f $lineNote, ( "Duration {0:hh}:{0:mm}:{0:ss} (!)" -f $duration )  
    } else {
        $lineNote = "{0} - {1}" -f $lineNote, ( "Duration {0:hh}:{0:mm}:{0:ss}" -f $duration )  
    }

    $lineNote = $lastSession.Result.ToString() + " - " + $lineNote
    if( $lastSession.Result -ne "Success" ) {
        if( $lastSession.Result -eq "Failed" ) {
            $lineStatus = [math]::Max(2, $lineStatus)
        }
        elseif( $lastSession.Result -eq "Warning" ) {
            $lineStatus = [math]::Max(1, $lineStatus)
        }
    } else {
        $lineStatus = [math]::Max(0, $lineStatus)
    }

    
    $lineId     = "veeam_job-" + $currentJob.Name
    $linePerf   = "{0}" -f $linePerf
    $lineNote = "{0} - see Details..." -f $lineNote

    Write-Host ( "{0} {1} {2} {3}" -f $lineStatus, $lineId, $linePerf, $lineNote )
}
