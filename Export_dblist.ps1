################ DESCRIPTION

## Returns Database Name and Size in MB for databases on a SQL server.

################

## Author: Vimal Patel
## Filename: Export_dblist.ps1
## Date: 2020/07/23
## Schedule it quarterly 
################ Path
#Read thru the contents of the file
$serverlist = Get-Content -Path C:\Users\vipatel\Desktop\serverlist.txt

#Create a new Excel object using COM 
$Excel = New-Object -ComObject Excel.Application
$Excel.visible = $True 
$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.Worksheets.Item(1)

#Counter variable for rows
$intRow = 1

#foreach($server in $serverlist)
foreach($instance in $serverlist)


{

<#
$stringarray = $server.Split(":")
$envname = $stringarray[0]
$instance = $stringarray[1]
#>
     #Create column headers
     #$Sheet.Cells.Item($intRow,1) = "Enviornment:"
     #$Sheet.Cells.Item($intRow,2) = $envname
     $Sheet.Cells.Item($intRow,3) = "SERVER NAME:"
     $Sheet.Cells.Item($intRow,4) = $instance
     $Sheet.Cells.Item($intRow,1).Font.Bold = $True
     $Sheet.Cells.Item($intRow,2).Font.Bold = $True
     #$Sheet.Cells.Item($intRow,3).Font.Bold = $True
     #$Sheet.Cells.Item($intRow,4).Font.Bold = $True

     $intRow++

     $Sheet.Cells.Item($intRow,1) = "DATABASE NAME"
     $Sheet.Cells.Item($intRow,2) = "COLLATION"
     $Sheet.Cells.Item($intRow,3) = "COMPATIBILITY LEVEL"
     $Sheet.Cells.Item($intRow,4) = "AUTOSHRINK"
     $Sheet.Cells.Item($intRow,5) = "RECOVERY MODEL"
     $Sheet.Cells.Item($intRow,6) = "SIZE (MB)"
     $Sheet.Cells.Item($intRow,7) = "SPACE AVAILABLE (MB)"

     #Format the column headers
     for ($col = 1; $col -le 7; $col++)
     {
          $Sheet.Cells.Item($intRow,$col).Font.Bold = $True
          $Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
          $Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
     }


     $intRow++
      #######################################################
     #This script gets SQL Server database information using PowerShell


     [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

     # Create an SMO connection to the instance
     $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $instance

     $dbs = $s.Databases

     #$dbs | SELECT Name, Collation, CompatibilityLevel, AutoShrink, RecoveryModel, Size, SpaceAvailable

     #Formatting using Excel 

     ForEach ($db in $dbs |Where-Object{$_.Name -ne 'master'-and $_.Name -ne 'model' -and $_.Name -ne 'msdb' -and $_.Name -ne 'tempdb'}) 
     {

          #Divide the value of SpaceAvailable by 1KB 
          $dbSpaceAvailable = $db.SpaceAvailable/1KB 

          #Format the results to a number with three decimal places 
          $dbSpaceAvailable = "{0:N3}" -f $dbSpaceAvailable 

          $Sheet.Cells.Item($intRow, 1) = $db.Name
          $Sheet.Cells.Item($intRow, 2) = $db.Collation
          $Sheet.Cells.Item($intRow, 3) = $db.CompatibilityLevel

           #Change the background color of the Cell depending on the AutoShrink property value 
           if ($db.AutoShrink -eq "True")
          {
               $fgColor = 3
          }
          else
          {
               $fgColor = 0
          }

          $Sheet.Cells.Item($intRow, 4) = $db.AutoShrink 
          $Sheet.Cells.item($intRow, 4).Interior.ColorIndex = $fgColor

          $Sheet.Cells.Item($intRow, 5) = $db.RecoveryModel
          $Sheet.Cells.Item($intRow, 6) = "{0:N3}" -f $db.Size

          #Change the background color of the Cell depending on the SpaceAvailable property value 
          if ($dbSpaceAvailable -lt 1.00)
          {
               $fgColor = 3
          }
           else
          {
               $fgColor = 0
          }

          $Sheet.Cells.Item($intRow, 7) = $dbSpaceAvailable 
          $Sheet.Cells.item($intRow, 7).Interior.ColorIndex = $fgColor

          $intRow ++

     }


$intRow ++

}

$Sheet.UsedRange.EntireColumn.AutoFit()
#cls
