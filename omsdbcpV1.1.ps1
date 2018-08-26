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

#Cleaning temp function
Function OMS-Clean-Temp
{
  write-host "Removing temporary files"
  rm -Force -Recurse ${driveLetter}\*.sqlite
}

#Cleaning all function
Function OMS-Clean-All
{
  write-host "Removing old Database"
  rm -Force -Recurse ${driveLetter}\*
}

#Database Copying function
Function OMS-Copy
{
  write-host "Copying new database"
  cp -Recurse ${folder}\ ${driveLetter}\
  write-host "Done, you can safely remove the sdcard" -ForegroundColor green
}


#Select Folder graphically
write-host "Select the MatchDatabases folder with the .sqlite file in it" -ForegroundColor Cyan

#Verify if MatchDatabases Folder is Selected
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

# Compute hash from Database (Too slow)
#$localhash = Get-FileHash $folder\* -Algorithm MD5

#Get Database name
$localdbname = ls ${folder}\*

write-host "Beginning script..." -ForegroundColor Gray
write-host "Insert sdcard" -ForegroundColor green

do
{
  $newEvent = Wait-Event -SourceIdentifier volumeChange
  $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
  $eventTypeName = switch($eventType)
  {
    1 {"Configuration changed"}
    2 {"Device arrival"}
    3 {"Device removal"}
    4 {"docking"}
  }
  write-host $eventTypeName -ForegroundColor gray
  if ($eventType -eq 2)
  {
    $driveLetter = $newEvent.SourceEventArgs.NewEvent.DriveName
    $driveLabel = ([wmi]"Win32_LogicalDisk='$driveLetter'").VolumeName
    #write-host "Drive name = " $driveLetter -ForegroundColor gray
    #write-host "Drive label = " $driveLabel -ForegroundColor gray

    # Execute process if drive matches specified condition(s)
    $sdmatch = ls $driveLetter | Select-String -Pattern 'MatchDatabases' -Quiet
    $sdtempfile = ls $driveLetter | Select-String -Pattern '.sqlite' -Quiet
    $sddbname = ls ${driveLetter}\MatchDatabases\*

    #if Temporary files are on the sdcard remove them
    if ($sdtempfile -eq 'True')
    {
      OMS-Clean-Temp
    }
    else
    {
      write-host "No Temp file to remove"
    }

    #if a database is on the sdcard it'll check if it'a the latest one
    if ($sdmatch -eq 'True')
    {
      if ($sdbname -ne $localdbname)
      {
        write-host "Updating Database..."
        OMS-Clean-All
        OMS-Copy
      }
      else
      {
        write-host "Current Database already on sdcard"
      }
      elseif ($sdmatch -ne 'True')
      {
        write-host "MatchDatabases folder not found. Continue ?" -ForegroundColor red
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        OMS-Clean-All
        OMS-Copy
      }
    }
    Remove-Event -SourceIdentifier volumeChange
} while (1-eq1) #Loop until next event
Unregister-Event -SourceIdentifier volumeChange
}