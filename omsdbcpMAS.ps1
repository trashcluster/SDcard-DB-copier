#Volume Detection 
Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier volumeChange

#Graphical interface for folder selection function
Function Select-FolderDialog
{
    param([string]$Description="Select Folder",[string]$RootFolder="Desktop")

 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
     Out-Null

   $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
        $objForm.Rootfolder = $RootFolder
        $objForm.Description = $Description
        $Show = $objForm.ShowDialog()
        If ($Show -eq "OK")
        {
            Return $objForm.SelectedPath
        }
        Else
        {
            Write-Error "Operation cancelled by user."
        }
    }

#Select Folder graphically
write-host "Select the MatchDatabase folder with the .sqlite file in it" -ForegroundColor Cyan

$folderc = 'False'
while ($folderc -eq 'False')
    {
    $folder = Select-FolderDialog
    $foldmatch = echo $folder | Select-String 'MatchDatabases' -Quiet
    write-host "Error ! Retry selecting MatchDatabases folder" -ForegroundColor Red
        if ($foldmatch -eq 'MatchDatabases')
        {
        $folderc = 'True'
        }
    }



write-host "Selected " $folder

write-host "Beginning script..." -ForegroundColor Gray

#Working Mode selecter
$menu = 0
while ($menu -eq 0)
	{
	$mode = Read-Host "1 - Update Databases `n2 - Clean Temp files `nSelect mode "
    if ($mode -eq 1 -or $mode -eq 2)
        {
            $menu = 1
        }
    else {write-host "Error !" -ForegroundColor red}
    }
write-host "Insert sdcard" -ForegroundColor green

do{
    $newEvent = Wait-Event -SourceIdentifier volumeChange
    $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
    $eventTypeName = switch($eventType)
    {
        1 {"Configuration changed"}
        2 {"Device arrival"}
        3 {"Device removal"}
        4 {"docking"}
    }
    write-host "Event detected = " $eventTypeName -ForegroundColor gray
    if ($eventType -eq 2)
    {
        $driveLetter = $newEvent.SourceEventArgs.NewEvent.DriveName
        $driveLabel = ([wmi]"Win32_LogicalDisk='$driveLetter'").VolumeName
        write-host "Drive name = " $driveLetter -ForegroundColor gray
        write-host "Drive label = " $driveLabel -ForegroundColor gray
        # Execute process if drive matches specified condition(s)
        $cond = ls $driveLetter | Select-String -Pattern 'MatchDatabase' -Quiet
        $cond2 = ls $driveLetter | Select-String -Pattern '.sqlite' -Quiet
        if ($cond -eq 'True' -and $mode -eq 1)
        {
            #Execute Database updating & Temp files removing
            write-host "MatchDatabase folder found"
            write-host "Wait..."
            start-sleep -seconds 1
            write-host "Removing old files"
            rm -Force -Recurse ${driveLetter}\*
            write-host "Copying new database"
            cp -Recurse ${folder}\ ${driveLetter}\
            write-host "Done, you can safely remove the sdcard" -ForegroundColor green
        }
        elseif ($cond -ne 'True' -and $mode -eq 1)
        {
            #execute Database Copying & Temp files removing
            write-host "MatchDatabase folder not found. Continue ?" -ForegroundColor red
            $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            write-host "Wait..."
            start-sleep -seconds 1
            write-host "Removing old files"
            rm -Force -Recurse ${driveLetter}\*
            write-host "Copying new database"
            cp -Recurse ${folder}\ ${driveLetter}\
            write-host "Done, you can safely remove the sdcard" -ForegroundColor green
        }
        elseif ($cond2 -eq 'True' -and $mode -eq 2)
        {
            #Execute Temp files cleaning
            write-host "Wait..."
            start-sleep -seconds 1
            write-host "Removing Temporary files"
            rm -Force ${driveLetter}\*.sqlite
            write-host "Done, you can safely remove the sdcard" -ForegroundColor green
        }
        elseif ($cond2 -ne 'True' -and $mode -eq 2)
        {
            #Execute nothing :)
            write-host "No files to clean !" -ForegroundColor red
            write-host "Done, you can safely remove the sdcard" -ForegroundColor green
        }
    }
    Remove-Event -SourceIdentifier volumeChange
} while (1-eq1) #Loop until next event
Unregister-Event -SourceIdentifier volumeChange
