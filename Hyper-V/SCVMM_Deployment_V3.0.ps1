#Accept CSV filename with Virtual Machine Information
#Please Run This Script as GIGHSW / GIGNWI account from SCVMM Server to avoid issues.
#param(
#    [parameter(Mandatory = $true)]
#    [string[]]$CSVfilename
#	)

Set-StrictMode -Version 1.0;

#requires -version 4.0 
#requires –runasadministrator

Clear;

[string]$Version                 = "3.0";

[string]$CSVfilename             = "C:\scripts\Final\GIG01_06_rebuildT02_7.csv";

[string]$SCVMServer              = "gig00clsscvmm01.cymru.nhs.uk";
[string]$GIG01PinHost            = "GIG01SRVHYP1A00.cymru.nhs.uk";
[string]$GIG06PinHost            = "GIG06SRVHYP1A00.cymru.nhs.uk";
[string]$primaryLibrary          = "\\gig01srvvmmlib1.cymru.nhs.uk\VMMLibraryPrimary\Scripts\unattend.xml";
[string]$secondaryLibrary        = "\\gig06srvvmmlib1.cymru.nhs.uk\VMMLibrarySecondary\Scripts\unattend.xml";
[string]$sourceOperatingSystem   = "Windows Server 2012 R2 Standard";
[string]$sourceCapabilityProfile = "Hyper-V";
[string]$TranscriptPath          = "C:\scripts\Final\Deploy_Logs\scvmmdeploy_log.txt";
[string]$HelperFile              = "SCVMM-Helper-Functions.ps1";
[string]$NewDVDDriveLetter       = "Z:";

[int]$NapTimer                   = 5;
[int]$SleepTimer                 = 10;
[int]$DeepSleepTimer             = 20;
[int]$DefaultMemoryGB            = 2048;
[int]$DefaultCPUCount            = 2;
[Array]$profilecleanup           = @();
[Array]$templatecleanup          = @();


# Check the Helper File exists
$SCVMMHelperFunctionsFile = Join-Path -Path $PSScriptRoot -ChildPath $HelperFile;
if ( Test-Path $SCVMMHelperFunctionsFile )
    {
        # Load the DSC Helper Functions
        . $SCVMMHelperFunctionsFile;
        Write-Host "SCVMM Helper Functions Loaded." -ForegroundColor Green;
    }
else
    {
        Write-Host "$SCVMMHelperFunctionsFile Not Found..." -ForegroundColor Red;
        exit 1;
    }

# Check the CSV File exists
if ( Test-Path $CSVFileName )
    {
        # Import the VMs to be built from the CSV File
        $Computernames = Import-CSV $CSVFilename -UseCulture;
        $Computernames = Get-SanitisedBuildList -ComputerNames $ComputerNames;
    }
else
    {
        Write-Host "$CSVFilename Not Found..." -ForegroundColor Red;
        exit 1;
    }

if( Test-Path $primaryLibrary ) { $sourceAnswerFile = $primaryLibrary; }
elseif ( Test-Path $secondaryLibrary ) { $sourceAnswerFile = $secondaryLibrary; }
else {   # Without the VMM Script Library, we are DOOMED!
        write-host "Cannot Find Library Server - Exiting..." -ForegroundColor Red;
        exit 1; 
     }

# Connect to SCVMM server
Load-PSModule VirtualMachineManager;
Get-SCVMMServer $SCVMServer | Out-Null;


$credential = Get-BuildCredentials;
Write-Host "Credentials Collected." -ForegroundColor Green;


# List all IP Addresses and return those IP addresses
# Which are not bound to a Virtual Adapter back into the pool
# Commented out until we are sure about the IP Addresses
#Set-CleanSCIPAddressPool;


Set-StopLogging;

Set-StartLogging -TranscriptPath $TranscriptPath;

Set-CheckDiskTemplateCompatability -ComputerNames $ComputerNames;


###########################################################
#
# Build Work Starts Here
#
###########################################################
Try
    {
        foreach($computername in $computernames)
            {

            $hostname             = $computername.vmname;
            $hostgroup            = $computername.hostgroup;
            $sourceTemplate       = $computername.template;
            $sourceVMNetwork      = $computername.vmnetwork;
            $sourceGuestOSProfile = $computername.guestosprofile;
            $vmLocation           = $computername.storagelocation;

            $VMJobGroup   = [guid]::NewGuid();
            $DiskJobGroup = [guid]::NewGuid();
            
            
            if($computername.MemoryGB -ne "") { $MemoryGB = ( [int]$computername.MemoryGB ) * 1024; }
            else { $MemoryGB = $DefaultMamoryGB; }

            if($computername.CPUCount -ne "") { $CPUCount = [int]$computername.CPUCount; }
            else { $CPUCount = $DefaultCPUCount; }

    
            #################################################################################################################################
            #                                                                                                                               #
            # Start Profile | Start Profile | Start Profile | Start Profile | Start Profile | Start Profile | Start Profile | Start Profile #
            #                                                                                                                               #
            #################################################################################################################################
                       
            ###########################################################
            #
            # Add a Virtual SCSI Adapter to the Hardware Profile
            #
            ########################################################### 
            New-SCVirtualScsiAdapter `
                -VMMServer $SCVMServer `
                -JobGroup $VMJobGroup `
                -AdapterID 7 `
                -ShareVirtualScsiAdapter $false `
                -ScsiControllerType DefaultTypeNoType `
                -ErrorAction stop | Out-Null;

            ###########################################################
            #
            # Add a Virtual DVD Drive on the SCSI Adapter to the Hardware Profile
            #
            ###########################################################            
            New-SCVirtualDVDDrive `
                -VMMServer $SCVMServer `
                -JobGroup $VMJobGroup `
                -Bus 0 `
                -LUN 10 `
                -ErrorAction stop | Out-Null;


            ###########################################################
            #
            # Add a Virtual Network Adapter to the Hardware Profile
            #
            ########################################################### 
            $VMNetwork = Get-SCVMNetwork -VMMServer $SCVMServer -Name $sourceVMNetwork;
            $VMSubnet = Get-SCVMSubnet -VMMServer $SCVMServer -Name $VMNetwork.VMSubnet.name;

            New-SCVirtualNetworkAdapter `
                -VMMServer $SCVMServer `
                -JobGroup $VMJobGroup `
                -MACAddress "00:00:00:00:00:00" `
                -MACAddressType Static `
                -VLanEnabled $false `
                -Synthetic `
                -EnableVMNetworkOptimization $false `
                -EnableMACAddressSpoofing $false `
                -EnableGuestIPNetworkVirtualizationUpdates $false `
                -IPv4AddressType Static `
                -IPv6AddressType Dynamic `
                -VMSubnet $VMSubnet `
                -VMNetwork $VMNetwork `
                -ErrorAction Stop | Out-Null;


            $CPUType = Get-SCCPUType -VMMServer $SCVMServer | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"};

            $CapabilityProfile = Get-SCCapabilityProfile -VMMServer $SCVMServer | where { $_.Name -eq $sourceCapabilityProfile };
            
            $NewProfile = [guid]::NewGuid();

            New-SCHardwareProfile `
                -VMMServer $SCVMServer `
                -CPUType $CPUType `
                -Name $NewProfile `
                -Description "Profile used to create a VM Template" `
                -CPUCount $CPUCount `
                -MemoryMB 1024 `
                -DynamicMemoryEnabled $true `
                -DynamicMemoryMinimumMB 512 `
                -DynamicMemoryMaximumMB $MemoryGB `
                -DynamicMemoryBufferPercentage 20 `
                -MemoryWeight 5000 `
                -CPUExpectedUtilizationPercent 20 `
                -DiskIops 0 `
                -CPUMaximumPercent 100 `
                -CPUReserve 0 `
                -NumaIsolationRequired $false `
                -NetworkUtilizationMbps 0 `
                -CPURelativeWeight 100 `
                -HighlyAvailable $true `
                -HAVMPriority 2000 `
                -DRProtectionRequired $false `
                -SecureBootEnabled $true `
                -CPULimitFunctionality $false `
                -CPULimitForMigration $false `
                -CapabilityProfile $CapabilityProfile `
                -Generation 2 `
                -JobGroup $VMJobGroup `
                -ErrorAction Stop | Out-Null;

            $profilecleanup += $NewProfile;


            ###############################################################################################################################
            #                                                                                                                             #
            # End Profile | End Profile | End Profile | End Profile | End Profile | End Profile | End Profile | End Profile | End Profile #
            #                                                                                                                             #
            ###############################################################################################################################





            ########################################################################################################################
            #                                                                                                                      #
            # Start Template | Start Template | Start Template | Start Template | Start Template | Start Template | Start Template #
            #                                                                                                                      #
            ########################################################################################################################


            ###########################################################
            #
            # Add Virtual Disk Drives on the SCSI Adapter to the Template
            #
            ########################################################### 
            if($computername.Disk2 -ne "")
                {
	                New-SCVirtualDiskDrive `
                        -VMMServer $SCVMServer `
                        -SCSI `
                        -Bus 0 `
                        -LUN 5 `
                        -JobGroup $DiskJobGroup `
                        -VirtualHardDiskSizeMB $([int]$computername.Disk2*1024) `
                        -CreateDiffDisk $false `
                        -Dynamic `
                        -Filename "$($hostname)_disk_2" `
                        -VolumeType None | Out-Null; 
                }

            if($computername.Disk3 -ne "")
                {
	                New-SCVirtualDiskDrive `
                        -VMMServer $SCVMServer `
                        -SCSI `
                        -Bus 0 `
                        -LUN 6 `
                        -JobGroup $DiskJobGroup `
                        -VirtualHardDiskSizeMB $([int]$computername.Disk3*1024) `
                        -CreateDiffDisk $false `
                        -Dynamic `
                        -Filename "$($hostname)_disk_3" `
                        -VolumeType None | Out-Null;
                }

            if($computername.Disk4 -ne "")
                {
	                New-SCVirtualDiskDrive `
                        -VMMServer $SCVMServer `
                        -SCSI `
                        -Bus 0 `
                        -LUN 7 `
                        -JobGroup $DiskJobGroup `
                        -VirtualHardDiskSizeMB $([int]$computername.Disk4*1024) `
                        -CreateDiffDisk $false `
                        -Dynamic `
                        -Filename "$($hostname)_disk_4" `
                        -VolumeType None | Out-Null;
                }

            if($computername.Disk5 -ne "")
                {
	                New-SCVirtualDiskDrive `
                        -VMMServer $SCVMServer `
                        -SCSI `
                        -Bus 0 `
                        -LUN 8 `
                        -JobGroup $DiskJobGroup `
                        -VirtualHardDiskSizeMB $([int]$computername.Disk5*1024) `
                        -CreateDiffDisk $false `
                        -Dynamic `
                        -Filename "$($hostname)_disk_5" `
                        -VolumeType None `
                        -ErrorAction stop | Out-Null;
                }

            $NewTemplate     = [guid]::NewGuid();
            $Template        = Get-SCVMTemplate -VMMServer $SCVMServer | where { $_.Name -eq $sourceTemplate };
            $HardwareProfile = Get-SCHardwareProfile -VMMServer $SCVMServer | where { $_.Name -eq $NewProfile };
            $GuestOSProfile  = Get-SCGuestOSProfile -VMMServer $SCVMServer | where { $_.Name -eq $sourceGuestOSProfile };
            $AnswerFile      = Get-SCScript -VMMServer $SCVMServer | where { $_.SharePath -eq $sourceAnswerFile };
            $OperatingSystem = Get-SCOperatingSystem -VMMServer $SCVMServer | where { $_.Name -eq $sourceOperatingSystem };

            New-SCVMTemplate `
                -Name $NewTemplate `
                -Template $Template `
                -HardwareProfile $HardwareProfile `
                -GuestOSProfile $GuestOSProfile `
                -JobGroup $DiskJobGroup `
                -ComputerName "$($hostname)" `
                -TimeZone 85  `
                -AnswerFile $AnswerFile `
                -MergeAnswerFile $false `
                -OperatingSystem $OperatingSystem `
                -ErrorAction stop | Out-Null;


            $templatecleanup += $NewTemplate;


            write-host "Computername is $hostname" -ForegroundColor Green;
            write-host "Source Template is $sourceTemplate" -ForegroundColor Green;
            write-host "Source VM network is $sourcevmnetwork" -ForegroundColor Green;
            write-host "Guest os Profile is $sourceGuestOSProfile" -ForegroundColor Green;
            write-host "VM Location is $vmLocation" -ForegroundColor Green;


            Start-Sleep $NapTimer;

            #########################################################################################################################
            #                                                                                                                       #
            # End Template | End Template | End Template | End Template | End Template | End Template | End Template | End Template #
            #                                                                                                                       #
            #########################################################################################################################

            ###############################################################################################################
            #                                                                                                             #
            # Start Configuration | Start Configuration | Start Configuration | Start Configuration | Start Configuration #
            #                                                                                                             #
            ###############################################################################################################
            $template = Get-SCVMTemplate -All | where { $_.Name -eq $NewTemplate };
            $virtualMachineConfiguration = New-SCVMConfiguration -VMTemplate $template -Name "$($hostname)";

            ###########################################################
            #
            # Add a New Name to the Virtual Machine Configuration
            #
            ###########################################################

            # Exclude nodes that are in maintenance mode
            $hosts = Get-SCVMHostGroup -VMMServer “gig00clsscvmm01.cymru.nhs.uk" -Name $hostgroup | Get-SCVMHost | where { $_.MaintenanceHost -ne “False” };
            
            $vmHost = $($hosts | get-random).name;
           


            Set-SCVMConfiguration `
                -VMConfiguration $virtualMachineConfiguration `
                -VMHost $vmHost | Out-Null;

            Update-SCVMConfiguration `
                -VMConfiguration $virtualMachineConfiguration | Out-Null;


            ###########################################################
            #
            # Configure the VM NIC to receive an IP Address from the IPv4 Address Pool
            #
            ###########################################################
            $IPV4AddressPool = Get-SCStaticIPAddressPool `
                                    -VMMServer $SCVMServer `
                                    -IPv4 `
                                    -Subnet $VMSubnet.SubnetVLans.subnet `
                                    -VMHostGroup $hostgroup `
                                    -ErrorAction Stop;

            $AllNICConfigurations = Get-SCVirtualNetworkAdapterConfiguration `
                                        -VMConfiguration $virtualMachineConfiguration;
            $NICConfiguration = $AllNICConfigurations[0];
            
            Set-SCVirtualNetworkAdapterConfiguration `
                -VirtualNetworkAdapterConfiguration $NICConfiguration `
                -IPv4AddressPool $IPV4AddressPool `
                -ErrorAction Stop | Out-Null;

            Update-SCVMConfiguration `
                -VMConfiguration $virtualMachineConfiguration | Out-Null;



            ###########################################################
            #
            # Add a VM Pin Location to the Virtual Machine Configuration
            #
            ########################################################### 
            Set-SCVMConfiguration `
                -VMConfiguration $virtualMachineConfiguration `
                -VMLocation $vmLocation `
                -PinVMLocation $true | Out-Null;

            Update-SCVMConfiguration `
                -VMConfiguration $virtualMachineConfiguration | Out-Null;



            ###########################################################
            #
            # Add the SCSI Disks to the Virtual Machine Configuration
            #
            ########################################################### 
            $VHDConfiguration = Get-SCVirtualHardDiskConfiguration -VMConfiguration $virtualMachineConfiguration;

            if($VHDConfiguration.count -eq 1)
                {
	                Set-SCVirtualHardDiskConfiguration `
                        -VHDConfiguration $VHDConfiguration `
                        -PinSourceLocation $false `
                        -PinDestinationLocation $false `
                        -FileName "$($hostname)_disk_1.vhdx" `
                        -DeploymentOption "UseNetwork" | Out-Null;
                }

            if($VHDConfiguration.count -gt 1)
                {
	                Set-SCVirtualHardDiskConfiguration `
                        -VHDConfiguration $VHDConfiguration[0] `
                        -PinSourceLocation $false `
                        -PinDestinationLocation $false `
                        -FileName "$($hostname)_disk_1.vhdx" `
                        -DeploymentOption "UseNetwork" | Out-Null;
	
    	            for($x = 1;$x -lt $VHDConfiguration.count;$x++)
	                    {
		                    Set-SCVirtualHardDiskConfiguration `
                                -VHDConfiguration $VHDConfiguration[$x] `
                                -PinSourceLocation $false `
                                -PinDestinationLocation $false `
                                -FileName "$($hostname)_disk_$($x + 1).vhdx" `
                                -DeploymentOption "None" | Out-Null;
	                    }
                }
 
            write-host "Updating SCVM Configuration..." -ForegroundColor Green;
            Update-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration | Out-Null;

            #########################################################################################################################
            #                                                                                                                       #
            # End Configuration | End Configuration | End Configuration | End Configuration | End Configuration | End Configuration #
            #                                                                                                                       #
            #########################################################################################################################


            ###############################################################################################################################
            #                                                                                                                             #
            # VM Creation | VM Creation | VM Creation | VM Creation | VM Creation | VM Creation | VM Creation | VM Creation | VM Creation #
            #                                                                                                                             #
            ############################################################################################################################### 
            write-host "Creating VM... $hostname" -ForegroundColor Green;
            write-host "`n`n";
            
            New-SCVirtualMachine `
                -Name "$hostname" `
                -VMConfiguration $virtualMachineConfiguration `
                -Description "" `
                -BlockDynamicOptimization $false `
                -StartVM `
                -JobGroup "$VMJobGroup" `
                -ReturnImmediately `
                -StartAction "NeverAutoTurnOnVM" `
                -StopAction "SaveVM" `
                -ErrorAction Stop | Out-Null;

        }
    }
Catch
    {
        Write-Host "VM Creation Error(s)..." -ForegroundColor Red;
        
        Set-CleanUpProfilesAndTemplates -ProfileCleanup $ProfileCleanup -TemplateCleanup $TemplateCleanUp;

		Write-Host $_.Exception.ToString();
		Exit 1;
    }


###########################################################
#
# Stop Transcript while Job Progress is displayed or it fills up the log
#
###########################################################
Set-StopLogging;

write-host "**** PROCESSING VM BUILDS ****" -ForegroundColor Green;
Start-Sleep $DeepSleepTimer;


###########################################################
#
# Let the VM's build now and monitor their progress
#
###########################################################
Set-MonitorVMBuildProgress -Computernames $Computernames;

Start-Sleep $DeepSleepTimer;

###########################################################
#
# Start the Logging again
#
###########################################################
Set-StartLogging -TranscriptPath $TranscriptPath;


###########################################################
#
# Disk Preparation Work
#
###########################################################
write-host "Starting Disk Preparation Work..." -ForegroundColor Green;
foreach($computername in $computernames)
    {

        $Template = $computername.template;
        $IPV4Addresses = $null;    
        $IPV4Addresses = Get-SCVirtualMachine -Name $computername.vmname -VMMServer $SCVMServer | Get-SCVirtualNetworkAdapter | select ipv4addresses;

        # If the Current VM's IP is blank
        # Something went wrong with the VM build
        # So skip it and move on
        if ( $IPV4Addresses -eq $null) { break; };

        $IP = $IPV4Addresses.IPV4Addresses[0];

        write-host "Retrieving IP of VM: $($computername.vmname) ... IP: " -ForegroundColor Green -NoNewline;
        write-host "$($IP)" -ForegroundColor Yellow;

	
	    #Start remote pssession to VM
	    $session = New-PSSession -computername $IP -credential $credential;
        $vmdisks = Invoke-Command -session $session -scriptblock { Get-Disk };


        if($($vmdisks.count) -eq $null)
            {
                $vmdiskcount = 1
            }
        else
            {
                $vmdiskcount = $($vmdisks.count)
            }

        # Find the CD/DVD Drive, and set the drive letter to be Z:
        $olddriveletter = (Get-WMIObject -class win32_cdromdrive -computer $IP).drive
        $cdvolume = Get-WMIObject -class win32_volume -computername $IP -filter "driveletter='$olddriveletter'";
        Set-WMIInstance -inputobject $cdvolume -arguments @{driveletter=$NewDVDDriveLetter} | Out-Null;
	

	    #Stop HWdetection Service
	    Invoke-Command -session $session -scriptblock { Stop-Service -name shellhwdetection };


	    #Get all raw disks (only those created by script / csv)
	    $RawDisks = Invoke-Command -session $session -scriptblock { Get-Disk | ? { $_.partitionstyle -eq 'raw' } };
	
        foreach ( $disk in $RawDisks )
            {

                Set-PrepareVMDisk -Disk $disk -Session $Session -Template $Template;

                Start-Sleep $NapTimer;
    
	        }

        #Start HWdetection Service
	    Invoke-Command -session $session -scriptblock { Start-Service -name shellhwdetection }
	
        Remove-PSSession $session;

   	    Start-Sleep $NapTimer;

}


###########################################################
#
# Set the Custom Properties for the Newly Created VM
#
###########################################################
Set-VMCustomProperties -ComputerNames $ComputerNames;


###########################################################
#
# Cleanup Profiles and Templates
#
###########################################################
Set-CleanUpProfilesAndTemplates -ProfileCleanup $ProfileCleanup -TemplateCleanup $TemplateCleanUp;


###########################################################
#
# Stop the Logging
#
###########################################################
Set-StopLogging;

Write-Host "VM Creation Completed..." -Foreground Green;
Write-Host "All DONE!..." -Foreground Green;