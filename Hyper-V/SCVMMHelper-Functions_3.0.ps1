###############################################################################################################
#                                                                                                             #
# Functions for Use within the Main PowerShell Code                                                           #
#                                                                                                             #
###############################################################################################################
function Template
{
    param ( [string]$Parameter )

    Try
        {
            # Code to add here
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Get-SanitisedBuildList
{
    param ( [Array]$ComputerNames )

    Try
        {
            [Array]$ComputersToBuild = @();
            foreach($Computername in $ComputerNames)
                {
                    $Computer = $Computername.Vmname;
	                if( Get-SCVirtualmachine $Computer )
	                    {                    
                            write-host "This VM already exists: `t $Computer" -ForegroundColor Red;
                            write-host "Skipping it and continuing with the remaining computers..." -ForeGroundColor Red;
                            Write-Host "`n";
	                    }
                    else
                        {
                            $ComputersToBuild += $Computername;
                        }
                }
            if ( $ComputersToBuild.count -eq 0 )
                {
                    Write-Host "No VMs to Build." -ForegroundColor Red;
                    exit 1;
                }
            else
                {
                    Write-Host "VMs Collected, Sanitised and Ready for Build." -ForegroundColor Green;
                    return ( ,$ComputersToBuild );
                }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Load-PSModule
{
    param ( [string]$ModuleName )

    Try
        {
            If ( -not( Get-Module -name $ModuleName ) ) 
                { 
                    If ( Get-Module -ListAvailable | Where-Object { $_.name -eq $ModuleName } ) 
                        { 
                            Write-Host "Importing Module $ModuleName..." -ForegroundColor Green -NoNewline;
                            Import-Module -Name $ModuleName -DisableNameChecking | Out-Null;
                            Write-Host "Completed." -Foregroundcolor Green;
                        } #end if module available then import 
                    else
                        { 
                            Write-Host "Module $ModuleName is not available on this system." -ForegroundColor Red;
                            Exit(1); 
                        } #module not available 
                } # end if not module 
            else
                {
                    Write-Host "Module $ModuleName is already loaded." -ForegroundColor Green;
                } #module already loaded 
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Get-BuildCredentials
{
    param ( )

    Try
        {

            # Credentials
            $password = "Poseid0n" | convertto-securestring -asPlainText -Force
            $username = "localhost\administrator"
            $credential = new-object System.Management.Automation.PSCredential($username,$password) 

            return ( $Credential );
        }
       Catch
             {
                    Write-Host $_.Exception.ToString();
                    Exit 1;
             }
}

function Set-CleanSCIPADdressPool
{
    param (  )

    Try
        {
            $assignedIPs = Get-SCIpaddress;

            Foreach ($ip in $assignedIPs)
                {
                     If ( $ip.AssignedToID -eq $null )
                         {
                             Write-Host "$($ip.Name) returned IP to Pool $($ip.AllocatingAddressPool)" -ForegroundColor Red;
                             $ip | Revoke-SCIPAddress -ReturnToPool $true
                         }
                }

        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Set-StopLogging
{
    param ( )

    Try
        {
            Write-Host "Turning off Transcripting..." -ForegroundColor Green;
            Stop-Transcript | out-null;
        }
	Catch
		{
      		Write-Host "Stop-Transcript Errored because the Transcript has not been started." -ForegroundColor Red;

		}
}

function Set-StartLogging
{
    param ( [string]$TranscriptPath )

    Try
        {
            Write-Host "(Re)Starting Transcripting..." -ForegroundColor Green;
            Start-Transcript -path $TranscriptPath -Force -Append;

        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Set-CheckDiskTemplateCompatability
{
    param ( [Array]$ComputerNames )

    Try
        {
            # Check Disk number in CSV , ensures we don't try to deploy a VM with a 2nd disk request 
            # If there are two disks in the the template for example.
            $diskcount = 0
            $anyDiskFailure = $false
            $diskfailure = $false
            write-host "`t`tTESTING CSV DISK COMPATIBILITY WITH TEMPLATE FOR DEPLOYMENT" -ForegroundColor Green;

            Start-Sleep $NapTimer;

            foreach($computername in $computernames)
            {

                $diskfailure = $false;
                $checktemplate = Get-SCVMTemplate -name $computername.template;
                $diskcount = $checktemplate.virtualdiskdrives.count;

                write-host "`n******************************" -Foreground Yellow;
                write-host "Computer Name:`t   $($computername.vmname)" -ForegroundColor Green;
                write-host "Disks in Template: $diskcount" -ForegroundColor Green;

                for($x = 2;$x -lt 5;$x++)
                {
                    $disk = 'disk' + $x
                    if(($computername.$disk) -ne "")
                    {
                        if($x -le $diskcount)
                        {
                            write-host -nonewline "Server Disk Config:"
                            write-host -ForegroundColor Red "FAILED"
                            write-host -foregroundcolor Yellow "`n INFORMATION:"
                            write-host -foregroundcolor Yellow "¯¯¯¯¯¯¯¯¯¯¯¯"
                            write-host -nonewline -foregroundcolor yellow "CSV also specifies disk `"" 
                            write-host -nonewline -foregroundcolor green "$x"
                            write-host "`""
                            write-host -foregroundcolor yellow "Incompatible with template" 

                            $anyDiskFailure = $true		        
                            $diskfailure = $true                
                        }
            
                    }
                }
                if( !$diskfailure )
                    {
                        write-host "`n******************************" -Foreground Yellow;
                        write-host "Server Disk Config: PASSED" -ForegroundColor Green;
                    }

                Start-Sleep $NapTimer;

            }

            if($anyDiskFailure)
                {
                    write-host "`n****************************" -ForegroundColor Red;
                    write-host -ForegroundColor red -NoNewline "`n ERROR: " -ForegroundColor Red;
                    write-host "`nCheck your CSV and try again." -ForegroundColor Red;
                    write-host "Exiting..." -ForegroundColor Red;
                    exit 1;
                }
            else
                {
                    write-host "`n******************************" -Foreground Yellow;
                    write-host "CSV / Server Disk Tests All Passed." -ForegroundColor Green;
                    write-host "Starting Deployment." -ForegroundColor Green;
                    write-host "`n`n" -ForegroundColor Green;
                }

        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Set-MonitorVMBuildProgress
{
    param ( [Array]$ComputerNames )

    Try
        {
            $working = $true

            while($working)
                {	

                    [Array]$deployjobs = @();
                    
                    foreach($vm in $computernames)
	                    {	

                            # Find any jobs which are still deploying.
                            $Job = Get-SCJob | ? { $_.name -eq "Create Virtual Machine" -and $_.status -eq "running" -and $_.resultname -eq "$($vm.vmname)" };
		                    $deployJobs += $Job;
	                    }

                    Clear;

                    # Show the current status and progress of the deploying jobs
	                $deployjobs | select resultname,name,status,progress
	
                    Start-Sleep $NapTimer;

                    # If there are no deploying jobs left
                    # then the VMs should be ready
	                if( $deployjobs.count -eq 0 )
                        {
                            $working = $false
                        }
	
                }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Set-PrepareVMDisk
{
    param ( [CimInstance]$disk, [System.Management.Automation.Runspaces.PSSession]$Session, [String]$Template )

    Try
        {
            
            #Get Disk Number   
		    $disknumber = $disk.Number;
        
            #Get Disk Letter, Initialize and Partition Disks
            $diskletter = Invoke-Command `
                                -session $session `
                                -scriptblock { Get-Disk -number $($args[0]) | `
                                               Initialize-Disk -PartitionStyle GPT -PassThru | `
                                               New-Partition -AssignDriveLetter -UseMaximumSize } `
                                -argumentlist $disknumber;
            $Drive = $diskletter.DriveLetter;

            Write-Host "`n`n";
            Write-Host "Initialising and Partitioning Disk... $disknumber, Disk letter... $Drive" -ForegroundColor Green;
        
	
            if ( $Template -match "SQL" )
                {
    		        #Format Disk Partitions
		            write-host "Formatting Volume...(64K Block Size)" -ForegroundColor Green;
                    
                    Switch ( $Drive ) 
                        {
                            'E' 
                                {
                                    $Command = "Format-Volume -driveletter E -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel `"DATA`" -Confirm:0; `
                                                New-Item -Path `"E:\DATA`" -ItemType directory";
                                }
                            'F'
                                {
                                    $Command = "Format-Volume -driveletter F -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel `"TEMPDB`" -Confirm:0; `
                                                New-Item -Path `"F:\TempDB`" -ItemType directory";
                                }
                            'G'
                                {
                                    $Command = "Format-Volume -driveletter G -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel `"LOGS`" -Confirm:0; `
                                                New-Item -Path `"G:\LOGS`" -ItemType directory";
                                }
                            default
                                {
                                    $Command = "Format-Volume -driveletter $Drive -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel `"UNKNOWN`" -Confirm:0";

                                }
                        }
                }
            else
                {
       		        #Format Disk Partitions
		            write-host "Formatting Volume...(Default Block Size)" -ForegroundColor Green;

                    $Command = "Format-Volume -driveletter $Drive -FileSystem NTFS -NewFileSystemLabel `"UNKNOWN`" -Confirm:0";
                }

                $ScriptBlock = [ScriptBlock]::Create($Command);

		        Invoke-Command -session $session -scriptblock $ScriptBlock;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Set-VMCustomProperties
{
    param ( [Array]$ComputerNames )

    Try
        {
            #Apply Custom Properties to VMs
            foreach($computername in $computernames)
                {
    
                    $SCVM = Get-SCVirtualMachine -Name $computername.vmname;

                    # If the Current VM is blank
                    # Something went wrong with the VM build
                    # So skip it and move on
                    if ( $SCVM -eq $null) { break; };

                    Set-SCVirtualMachine -VM $SCVM -Description $computername.Description | Out-Null;

                    $customProperty =  get-sccustomproperty | ? {$_.name -eq "Server_Role"}
                    Set-SCCustomPropertyValue -CustomProperty $customProperty -InputObject $SCVM -Value $computername.Server_Role | Out-Null;

                    $customProperty =  get-sccustomproperty | ? {$_.name -eq "National_Service"}
                    Set-SCCustomPropertyValue -CustomProperty $customProperty -InputObject $SCVM -Value $computername.National_Service | Out-Null;

                    $customProperty =  get-sccustomproperty | ? {$_.name -eq "Support_Service_Owner"}
                    Set-SCCustomPropertyValue -CustomProperty $customProperty -InputObject $SCVM -Value $computername.Support_Service_Owner | Out-Null;

                    $customProperty =  get-sccustomproperty | ? {$_.name -eq "Change_Request"}
                    Set-SCCustomPropertyValue -CustomProperty $customProperty -InputObject $SCVM -Value $computername.Change_Request | Out-Null;

                    set-adcomputer $computername.vmname -description $computername.Description | Out-Null;
    
                }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Set-CleanUpProfilesAndTemplates
{
    param ( [Array]$ProfileCleanup, [Array]$TemplateCleanup )

    Try
        {
            foreach($Profile in $profilecleanup)
                {
	                $ProfileToRemove = Get-SCHardwareProfile | where { $_.name -eq $Profile };
                    if ( $ProfileToRemove -ne $null )
                        {
        	                Remove-SCHardwareProfile -HardwareProfile $ProfileToRemove | Out-Null;
                        }
                }

            foreach($Template in $templatecleanup)
                {
	                $TemplateToRemove = Get-SCVMTemplate | where { $_.name -eq $Template };
                    if ( $TemplateToRemove -ne $null )
                        {
	                        Remove-SCVMTemplate -vmtemplate $TemplateToRemove | Out-Null;
                        }
                }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}










