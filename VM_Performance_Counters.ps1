
########################################################################################################

################################## Connect to database #################################################
## Variables 
$data_servername = "TOTDMTDBDEV03"
$data_database = "SQLPERF_VP"
$your_user = $null
$your_password =$null
$integrated_security = "True"
$error_location = "C:\temp\output_connection_error.txt"

########################################################################################################

################################ Function to add logfile entries #######################################

# call this fucntion with parameter message and level , there are 3 levels "Error","Warn","Info"

function write-Log 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 
 
        [Parameter(Mandatory=$false)] 
        [Alias('LogPath')] 
        [string]$Path='C:\Temp\PowerShellLog.log', 
	    #[string]$Path=$copylogfiles,
         
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warn","Info")] 
        [string]$Level="Info", 
         
        [Parameter(Mandatory=$false)] 
        [switch]$NoClobber 
    ) 
 
    Begin 
    { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'Continue' 
        
        if($Path -eq '')
        {
            $currentpath = Get-Location
            $filename = "powershell_logfile.log"
            $Path = "$currentpath\$filename"
        }
    } 
    Process 
    { 
         
        # If the file already exists and NoClobber was specified, do not write to the log. 
        if ((Test-Path $Path) -AND $NoClobber) { 
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name." 
            Return 
            } 
 
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
        elseif (!(Test-Path $Path)) { 
            Write-Verbose "Creating $Path." 
            $NewLogFile = New-Item $Path -Force -ItemType File 
            } 
 
        else { 
            # Nothing to see here yet. 
            } 
 
        # Format Date for our Log File 
        $FormattedDate = Get-Date -Format "{yyyy-MM-dd HH:mm:ss}" 
 
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
        switch ($Level) { 
            'ErrorMsg' { 
                Write-Error $Message 
                $LevelText = 'ERROR:' 
                } 
            'Warn' { 
                Write-Warning $Message 
                $LevelText = 'WARNING:' 
                } 
            'Info' { 
                Write-Verbose $Message 
                $LevelText = 'INFO:' 
                } 
            } 
         
        # Write log entry to $Path 
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append 
    } 
    End 
    { 
    } 
}

#$copylogfiles = 'C:\Users\ViPatel\Desktop\AzCost\PowerShellLog.log'

#write-log "Testings"

#######################################################################################################

# 1 DEFINE HELPER FUNCTIONS (CAN BE REUSED)
# function that connects to an instance of SQL Server / Azure SQL Server and saves the 
# connection object as a global variable for future reuse
function ConnectToDB {
    # define parameters
    param(
        [string]
        $servername,
        [string]
        $database,
        [string]
        $sqluser,
        [string]
        $sqlpassword
    )
    # create connection and save it as global variable
    $global:Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "server='$servername';database='$database';trusted_connection=True; user id = '$sqluser'; Password = '$sqlpassword'; integrated security= $integrated_security"
    $Connection.Open()
    Write-Verbose 'Database Connection established'
    write-log 'Database Connection established'
}
# function that executes sql commands against an existing Connection object; In pur case
# the connection object is saved by the ConnectToDB function as a global variable
function ExecuteSqlQuery {
    # define parameters
    param(
     
        [string]
        $sqlquery
    
    )
    
    Begin {
        If (!$Connection) {
            Throw "No connection to the database detected. Run command ConnectToDB first."
        }
        elseif ($Connection.State -eq 'Closed') {
            Write-Verbose 'Connection to the database is closed. Re-opening connection...'
            try {
                # if connection was closed (by an error in the previous script) then try reopen it for this query
                $Connection.Open()
            }
            catch {
                Write-Verbose "Error re-opening connection. Removing connection variable."
                Remove-Variable -Scope Global -Name Connection
                throw "Unable to re-open connection to the database. Please reconnect using the ConnectToDB commandlet. Error is $($_.exception)."
            }
        }
    }
    
    Process {
        #$Command = New-Object System.Data.SQLClient.SQLCommand
        $command = $Connection.CreateCommand()
        $command.CommandText = $sqlquery
    
        Write-Verbose "Running SQL query '$sqlquery'"
        try {

            $result = $command.ExecuteReader()      
        }
        catch {
            $Connection.Close()
        }
        $Datatable = New-Object "System.Data.Datatable"
        $Datatable.Load($result)
        return $Datatable          
    }
    End {
        Write-Verbose "Finished running SQL query."
    }
}
# 2 BEGIN EXECUTE (CONNECT ONCE, EXECUTE ALL QUERIES)

ConnectToDB -servername $data_servername -database $data_database -sqluser $your_user -sqlpassword $your_password 



################################# Function to Capture Resource Type data into table #################################################### 
#Fucntion to manipulate the location data

writePerfCounter "Up" $name $dt $adsr $adsw $adst $drs $dws $dts  $dbs $drbs $dwbs

Function writePerfCounter
{
param(  $p_status,
        $p_sname,
        $p_dt, 
        $p_adsr, 
        $p_adsw, 
        $p_adst, 
        $p_drs, 
        $p_dws, 
        $p_dts, 
        $p_dbs, 
        $p_drbs, 
        $p_dwbs)

        #call the invoke-sqlcmdlet to execute the query
         
         $insert_res = "Exec SP_INSERT_VM_SERVER_PERFCOUNTER '$p_status','$p_sname','$p_dt', '$p_adsr', '$p_adsw', '$p_adst', '$p_drs', '$p_dws', '$p_dts', '$p_dbs', '$p_drbs', '$p_dwbs'"
         #$insert_res = "Exec SP_INSERT_VM_SERVER_PERFCOUNTER '$az_resourceGroupName', '$az_resourceid' ,'$az_resource_kind' ,'$az_resource_location' ,'$az_managedby' ,'$az_resource_name' ,'$az_parent_resource' ,'$az_ResourceTypeName' ,'$az_ProviderNamespace'"

         write-host 'Insert --------' $insert_res -ForegroundColor Red
         ExecuteSqlQuery -sqlquery $insert_res

}

$Output= @()
$names = Get-content "C:\temp\vm_list.txt"

for ($i=101; $i -le 120; $i++)
 {
 write-host "###############################################################################################################################################################################" -ForegroundColor Green
 Write-host "#####################" $i
 write-host "###############################################################################################################################################################################" -ForegroundColor Green
 write-log " Count - $i"
 
foreach ($name in $names){
  if (Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue){
   
     #counter
     
     # Define our list of counters
			$counters = @(
                        "\PhysicalDisk(_Total)\Avg. Disk sec/Read",
                        "\PhysicalDisk(_Total)\Avg. Disk sec/Write",
                        "\PhysicalDisk(_Total)\Avg. Disk sec/Transfer",
                        "\PhysicalDisk(_Total)\Disk Reads/sec",
                        "\PhysicalDisk(_Total)\Disk Writes/sec",
                        "\PhysicalDisk(_Total)\Disk Transfers/sec",
                        "\PhysicalDisk(_Total)\Disk Bytes/sec",
                        "\PhysicalDisk(_Total)\Disk Read Bytes/sec",
                        "\PhysicalDisk(_Total)\Disk Write Bytes/sec"
                        )


        
			# Get performance counter data
			$ctr = Get-Counter -ComputerName $name -Counter $counters -SampleInterval 1 -MaxSamples 1
			$dt = $ctr.Timestamp

			foreach ($ct in $ctr.CounterSamples) {
				if ($ct.Path -like '*Avg. Disk sec/Read') {
					$adsr = $ct.CookedValue
					}
				if ($ct.Path -like '*Avg. Disk sec/Write') {
					$adsw = $ct.CookedValue
					}
				if ($ct.Path -like '*Avg. Disk sec/Transfer') {
					$adst = $ct.CookedValue
					}
				if ($ct.Path -like '*Disk Reads/sec') {
					$drs = $ct.CookedValue
					}
				if ($ct.Path -like '*Disk Writes/sec') {
					$dws = $ct.CookedValue
					}
				if ($ct.Path -like '*Disk Transfers/sec') {
					$dts = $ct.CookedValue
					}
				if ($ct.Path -like '*Disk Bytes/sec') {
					$dbs = $ct.CookedValue
					}
				if ($ct.Path -like '*Disk Read Bytes/sec') {
					$drbs = $ct.CookedValue
					}
				if ($ct.Path -like '*Disk Write Bytes/sec') {
					$dwbs = $ct.CookedValue
					}
				}

    write-host $dt $adsr $adsw $adst $drs $dws $dts  $dbs $drbs $dwbs

    writePerfCounter "Up" $name $dt $adsr $adsw $adst $drs $dws $dts $dbs $drbs $dwbs

    $Output+= "Up ,$name,$dt, $adsw ,$adst, $drs, $dws, $dts,  $dbs, $drbs, $dwbs"
    Write-Host "Up $Name, Numberofcores-$nc, Total Memory-$totalmemory GB"
    write-host -ForegroundColor Yellow "-----------------------------------------------------"
    Clear-Variable -Name "nc","ms","totalmemory"
  }
  else{
    $time = get-date
    $Output+= "$name,down"
    Write-Host "$Name,down"
    writePerfCounter "down" $name $time 0 0 0 0 0 0 0 0 0
  }
}
}
$Output | Out-file "C:\temp\result.csv"
