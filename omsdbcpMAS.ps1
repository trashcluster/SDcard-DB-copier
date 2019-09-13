#Shenanigan needed for the script to work, idk what it does but it makes the script detect peripherals
Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier volumeChange

############################################"Functions Definition"######################################
#Graphical interface for folder selection function, Copied from StackOverflow.
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


#Expected behaviour, no error :)
Function CleanAndCopyFunc
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

#When MatchDatabases is not found on the card, useful if u plug in a usb key and don't want to erase it !
Function MDatabaseNotFound
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

#Clean. Temp. Files. Quite literally.
Function CleanTempFiles
{
    #Execute Temp files cleaning
    write-host "Wait..."
    start-sleep -seconds 1
    write-host "Removing Temporary files"
    rm -Force ${driveLetter}\*.sqlite
    write-host "Done, you can safely remove the sdcard" -ForegroundColor green
}

#If there's no files to clean.
Function CleanTempFiles2
{
    #Execute nothing :)
    write-host "No files to clean !" -ForegroundColor red
    write-host "Done, you can safely remove the sdcard" -ForegroundColor green
}
###################################################"End Of Functions Definition"###################################

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


#Return selected folder
write-host "Selected " $folder

write-host "Beginning script..." -ForegroundColor Gray

#Working Mode selecter, 1 to clean the card and copy the database. 2 to only clean the two temp .sqlite files.
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

####################################SD-Card detection function, copied from StackOverflow ####################################
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
##################################"Actions to execute upon card detection"#####################################""
        write-host "Drive name = " $driveLetter -ForegroundColor gray
        write-host "Drive label = " $driveLabel -ForegroundColor gray
        # Execute process if drive matches specified condition(s)
        $cond = ls $driveLetter | Select-String -Pattern 'MatchDatabase' -Quiet
        $cond2 = ls $driveLetter | Select-String -Pattern '.sqlite' -Quiet
        if ($cond -eq 'True' -and $mode -eq 1)
        {
            CleanAndCopyFunc
        }
        elseif ($cond -ne 'True' -and $mode -eq 1)
        {
           MDatabaseNotFound
        }
        elseif ($cond2 -eq 'True' -and $mode -eq 2)
        {
            CleanTempFiles
        }
        elseif ($cond2 -ne 'True' -and $mode -eq 2)
        {
            CleanTempFiles2
        }
######################################"Where SDcard detection actions end"#########################################""
    }
    Remove-Event -SourceIdentifier volumeChange
} while (1-eq1) #Loop until next event
Unregister-Event -SourceIdentifier volumeChange
