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

function ConvertPSObjectToHashtable
{
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertPSObjectToHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertPSObjectToHashtable $property.Value
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}

function Import-DSCConfigurationFromJSON
{
    param ( [string]$DSCConfigurationDataFile )

    Try
        {
            $PSObject = (Get-Content  $DSCConfigurationDataFile ) -join "`n" | ConvertFrom-Json;
            $DSCConfigurationData = ConvertPSObjectToHashtable $PSObject;

            return ( $DSCConfigurationData );
        }
       Catch
             {
                    Write-Host $_.Exception.ToString();
                    Exit 1;
             }
}

function Install-RemoteCertificate
{
    param ( [string]$TargetNodeName, [string]$CertFile, [string]$PFXFile, [string]$PFXPassword, [PSCredential]$DomainBuildCred )

    Try
        {
            # Introduced in Version 1.2 - Remotely Install Certificate(s)
            Copy-Item $CertFile "\\$TargetNodeName\C`$\Windows\Temp" -Force;
            Copy-Item $PFXFile "\\$TargetNodeName\C`$\Windows\Temp" -Force;

            $ScriptCommand = "Import-Certificate -CertStoreLocation Cert:\LocalMachine\My -FilePath `"C:\Windows\Temp\DSCPublicKey.cer`"; `
                              Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -FilePath `"C:\Windows\Temp\DSCPrivateKey.pfx`" -Password (ConvertTo-SecureString -String `"$PFXPassword`" -AsPlainText -Force); ";
            $CommandScriptBlock = [Scriptblock]::Create($ScriptCommand)
            Invoke-Command -ComputerName $TargetNodeName -ScriptBlock $CommandScriptBlock -Credential $DomainBuildCred;

            Remove-Item "\\$TargetNodeName\C`$\Windows\Temp\DSCPublicKey.cer" -Force;
            Remove-Item "\\$TargetNodeName\C`$\Windows\Temp\DSCPrivateKey.pfx" -Force;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
            write-host "Function Install-RemoteCertificate ERROR:  try adding certificates manually and commenting out th call to this function";
			Exit 1;
		}
}

function Get-BuildCredentials
{
    param ( [string]$SQLFeatureList)

    Try
        {

            # Credentials
            $DomainAdminBuildCred = Get-Credential -UserName "CYMRU\GIGNWI_KA080214" -Message "Enter the Domain Admin Account Details";

            $DomainBuildCred = Get-Credential -UserName "CYMRU\GIGNWI_DSCAdmin" -Message "Enter the Build Account Details";

            if ( $SQLFeatureList -match "SQLENGINE" )
                {
                    $sqlServiceCred = Get-Credential -UserName "CYMRU\SASQL" -Message "Enter the SQL Server SERVICE Account Details";             

                    $sqlAgentCred = Get-Credential -UserName "CYMRU\SASQL" -Message "Enter the SQL Server AGENT Account Details";
                    
                    $SACred = Get-Credential -UserName "sa" -Message "Enter the Password for the SQL sa Account";

                }
            if ( $SQLFeatureList -match "AS" )
                {
                    
                    $SSASCred = Get-Credential -UserName "CYMRU\SQLSSASAccount" -Message "Enter the Password for the Analysis Services Account";

                }
            if ( $SQLFeatureList -match "RS" )
                {
                    
                    $SSRSCred = Get-Credential -UserName "CYMRU\SQLSSRSAccount" -Message "Enter the Password for the Reporting Services Account";

                }
            if ( $SQLFeatureList -match "IS" )
                {
                    
                    $SSISCred = Get-Credential -UserName "CYMRU\SQLSSISAccount" -Message "Enter the Password for the Integration Services Account";

                }

            return ( $DomainAdminBuildCred, $DomainBuildCred, $sqlServiceCred, $sqlAgentCred, $SACred, $SSASCred, $SSRSCred, $SSISCred );
        }
       Catch
             {
                    Write-Host $_.Exception.ToString();
                    Exit 1;
             }
}

function Get-FireWallPath
{
    param ( [string]$SQLVersion, [string]$SQLInstallDataDir, [string]$SQLInstanceName )

    Try
        {
            # Introduced in Version 1.3
            If ($SQLInstanceName -eq "") # If the SQL Server Instance Name is left blank - set it to the default.
                {
                   $SQLInstanceName = "MSSQLSERVER";
                } 


            Switch ($SQLVersion) {
                'SQL2012' {
                    $SQLProgram     = Join-Path -Path $SQLInstallDataDir -ChildPath "MSSQL11.$SQLInstanceName\MSSQL\Binn\sqlservr.exe";
                    }
                'SQL2014' {
                    $SQLProgram     = Join-Path -Path $SQLInstallDataDir -ChildPath "MSSQL12.$SQLInstanceName\MSSQL\Binn\sqlservr.exe";
                    }
                'SQL2016' {
                    $SQLProgram     = Join-Path -Path $SQLInstallDataDir -ChildPath "MSSQL13.$SQLInstanceName\MSSQL\Binn\sqlservr.exe";
                    }
                'SQL2017' {
                    $SQLProgram     = Join-Path -Path $SQLInstallDataDir -ChildPath "MSSQL14.$SQLInstanceName\MSSQL\Binn\sqlservr.exe";
                    }
                default {
                    Write-Output "Version of SQL is not Set correctly...";
                    Write-Output "Don't know what Version to install...";
                    Write-Output "Don't know how to set FireWall rules...";
                    Write-Output "Don't know what features are required...";
                    Write-Output "Terminating...";
                    Exit(1);
                    }
                }

            return ( $SQLProgram );
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Check-ADAccountExists
{
    param ( [PSCredential]$AccountCredential )

    Try
        {
            $AccountUserName = $AccountCredential.Username;
            $AccountPassword = $AccountCredential.Password;
            ( $Domain, $Username ) = $AccountUserName.split("\\");

            if (( Get-aduser -Filter { Name -eq $Username } ) -ne $null )
            {
                write-host "AD Account: $AccountUserName already exists" -ForegroundColor Green;
            }
        else
            {
                New-aduser `
                    -Name $Username `
                    -samaccountname $Username `
                    -AccountPassword $AccountPassword `
                    -DisplayName $Username `
                    -Enabled $true `
                    -OtherAttributes @{'AttributeLDAPDisplayName'=$Username};
                
                $Password = $AccountCredential.GetNetworkCredential().password

                Write-Host "New AD User Created: $UserName, with Chosen password: $Password.";
            }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Check-ADClusterCNOExists
{
    param ( [String]$ClusterName )

    Try
        {
            $CNOObject = Get-ADComputer $ClusterName;
            if ( $CNOObject )
            {
                write-host "AD CNO for: $ClusterName already exists" -ForegroundColor Green;
                Write-Host "Making sure the CNO is DISABLED." -ForegroundColor Green;
                if ( $CNOObject.Enabled -eq $true )
                    {
                        Disable-ADAccount $CNOObject;
                    }
            }
        else
            {
                Write-Host "AD CNO for: $ClusterName does not exist" -ForegroundColor Red;
                exit(1);
            }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Check-ADComputerAccountInTargetOU 
{
    param ( [string]$TargetNodeName, [string]$TargetOU, [PSCredential]$DomainAdminBuildCred )

    Try
        {
            #Get the current OU of the TargetNodeName
            $ComputerObject = Get-ADComputer $TargetNodeName;
            $CurrentOU = $ComputerObject.DistinguishedName.Substring($ComputerObject.DistinguishedName.IndexOf('OU='));

            # If the CurrentOU is NOT the TargetOU, Move it
            If ( $CurrentOU -ne $TargetOU )
                {
                    Move-ADObject -Identity $ComputerObject -TargetPath $TargetOU -Credential $DomainAdminBuildCred;

                }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Get-BroadcastAddress
{
    param ( [IpAddress]$ip, [IpAddress]$Mask )
    
    Try
        {
            $IpAddressBytes = $ip.GetAddressBytes()
            $SubnetMaskBytes = $Mask.GetAddressBytes()
 
            if ($IpAddressBytes.Length -ne $SubnetMaskBytes.Length)
                {
                    throw "Lengths of IP address and subnet mask do not match."
                    exit 0
                }
 
            $BroadcastAddress = @()
 
            for ($i=0;$i -le 3;$i++) 
                {
                    $a = $subnetMaskBytes[$i] -bxor 255
                    if ($a -eq 0) 
                        {
                            $BroadcastAddress += $ipAddressBytes[$i]
                        }
                    else 
                        {
                            $BroadcastAddress += $a
                        }
                }
 
                $BroadcastAddressString = $BroadcastAddress -Join "."
    
                return [IpAddress]$BroadcastAddressString;
                
            }
	Catch
		    {
			    Write-Host $_.Exception.ToString();
			    Exit 1;
		    }
}
 
function Get-NetworkAddress
{
    param ( [IpAddress]$ip, [IpAddress]$Mask )
    
    Try
        {
            $IpAddressBytes = $ip.GetAddressBytes();
            $SubnetMaskBytes = $Mask.GetAddressBytes();
 
            if ($IpAddressBytes.Length -ne $SubnetMaskBytes.Length) 
                {
                    throw "Lengths of IP address and subnet mask do not match.";
                    exit 0;
                }
 
            $BroadcastAddress = @();
 
            for ($i=0;$i -le 3;$i++) 
                {
                    $BroadcastAddress += $ipAddressBytes[$i]-band $subnetMaskBytes[$i];
                }
 
            $BroadcastAddressString = $BroadcastAddress -Join ".";
    
            return [IpAddress]$BroadcastAddressString;
            }
	Catch
		    {
			    Write-Host $_.Exception.ToString();
			    Exit 1;
		    }
}
 
function Check-IsInSameSubnet 
{
    param ( [IpAddress]$ip1, [IpAddress]$ip2, [IpAddress]$mask )
 
    Try
        { 
            $Network1 = Get-NetworkAddress -ip $ip1 -mask $mask;
            $Network2 = Get-NetworkAddress -ip $ip2 -mask $mask;
 
            return $Network1.Equals($Network2);

        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Check-ClusterIPAddress
{
    param ( [string]$PrimaryNode, [string]$Cluster_IPAddress )

    Try
        {
            ( $ClusterIPAddress, $Rubbish ) = $Cluster_IPAddress1.split("/");

            # PrimaryNode *may* have more than 1 IP Address, so we need to check them all
            # If we take the IP address which has a default gateway assigned we should be correct.
            # Check if the server is online before doing the remote command

            If (Test-Connection -ComputerName $PrimaryNode -Quiet -count 1)
                {
                    $EthernetAdapters = Get-WmiObject `
                                            -ComputerName $PrimaryNode `
                                            -query "select * from Win32_NetworkAdapterConfiguration where IPEnabled = $true" | `
                                        Where-Object { $_.defaultIPGateway -ne $null }; 
                                        
                    foreach ($EthernetAdapter in $EthernetAdapters)
                        {
                            # We need the IPV4 address, not the IPV6
                            for ( $index = 0; $index -lt ( $EthernetAdapter.IPAddress.Count-1 ); $index++ )
                                {
                                    $index |  where { $EthernetAdapter.IPAddress[$_] -notmatch "fe80" } | Out-Null;
                                    $SubnetMask = $EthernetAdapter.IPSubnet[$index];
                                    $IPAddress = $EthernetAdapter.IPAddress[$index];

                                    $result = Check-IsInSameSubnet -ip1 $IPAddress -ip2 $ClusterIPAddress -mask $SubnetMask;

                                    if ( $result -eq $true ) { break; }
                                }

                            if ($result -eq $false )
                                {
                                    Write-Host "Cluster IP Address $ClusterIPAddress1 Cannot be hosted on $PrimaryNode with IP Address $IPAddress" -ForegroundColor Red;
                                    Write-Host "The Node $PrimaryNode is probably in the wrong Subnet?..." -ForegroundColor Red;
                                    Write-Host "Try Swapping the Cluster IP Addresses over in the Configuration File..." -ForegroundColor Red;
                                    exit(1);
                                }
                        }
                }

        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function BackupConfigurationFile
{
    param ( [string]$ConfigurationDataFile )

    Try
        {
            # Backup the Configuration File for future reference
            $Directory   = [System.IO.Path]::GetDirectoryName($ConfigurationDataFile);
            $File        = [System.IO.Path]::GetFileNameWithoutExtension($ConfigurationDataFile);
            $Extension   = [System.IO.Path]::GetExtension($ConfigurationDataFile);
            $Now         = Get-Date -Format "MM-dd-yyyy_hh-mm-ss";
            $NewDataFile = Join-Path -Path $Directory -ChildPath "$File.$Now$Extension";

            Copy-Item $ConfigurationDataFile $NewDataFile -Force;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function ConnectSQLExecProc
{
    param ( [string]$NodeName, [string]$InstanceName, [string]$Database, [string]$StoredProc, [string]$Parameters )

    Try
        {
            
            if (( $InstanceName -eq "MSSQLSERVER" ) -or ( $InstanceName -eq "" ))
                {
                    $SQLServer =  $NodeName;
                }
            else
                {
                    $SQLServer = $NodeName + '\' + $InstanceName;
                }
 
            $SqlQuery = 'EXEC ' + $StoredProc + ' ''' + $Parameters + '''';
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = “Server=$SQLServer;Database=$Database;Integrated Security=True”;
            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand;
            $SqlCmd.CommandText = $SqlQuery;
            $SqlCmd.Connection = $SqlConnection;
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter;   
            $SqlAdapter.SelectCommand = $SqlCmd;
            $DataSet = New-Object System.Data.DataSet;
            $SqlAdapter.Fill($DataSet);
            $SqlConnection.Close();
 
            return ($DataSet);
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Export-DSCConfigurationToJSON
{
    param ( [string]$DSCManagerHost, [string]$DSCManagerInstanceName, [string]$DSCDatabase, [string]$StoredProcParams, [string]$DSCConfigurationDataFile )

    Try
        {
            ###############################################################################################################
            #                                                                                                             #
            #  Execute Stored Procedures against SQL Server to gather the required data                                   #
            #                                                                                                             #
            ###############################################################################################################

            $Result = @();
            $GenericData = @{};
            $NodeData = @{};

            # Execute the Get_GenericConfig Stored Procedure to return the
            # Generic build data and add this to the config array
            $StoredProcedure = "[Build].[Get_GenericConfig]";
            ( $Data ) = ConnectSQLExecProc -NodeName $DSCManagerHost `
                                           -InstanceName $DSCManagerInstanceName `
                                           -Database $DSCDatabase `
                                           -StoredProc $StoredProcedure `
                                           -Parameters $StoredProcParams;


            foreach ( $row in $Data.Tables[0].Rows)
            {
                foreach ($Column in $Data.Tables[0].Columns)
                {
                    $GenericData.Add($Column.ColumnName, $row[$column].ToString());
                }
            }
            $Result += ( $GenericData );
            Write-Host "Generic Build Data Collected from SQL..." -ForegroundColor Green;


            # Execute the Get_Get_NodeConfig Stored Procedure to return the
            # Node specific build data and add this to the config array

            $StoredProcedure = "[Build].[Get_NodeConfig]";
            ( $Data ) = ConnectSQLExecProc -NodeName $DSCManagerHost `
                                           -InstanceName $DSCManagerInstanceName `
                                           -Database $DSCDatabase `
                                           -StoredProc $StoredProcedure `
                                           -Parameters $StoredProcParams;

            for ( $i=0; $i -lt $Data.Tables[0].Rows.Count; $i++ )
                {
                    $NodeData = @{};
                    foreach ( $row in $Data.Tables[0].Rows[$i])
                    {
                        foreach ($Column in $Data.Tables[0].Columns)
                        {
                            $NodeData.Add($Column.ColumnName, $row[$column].ToString());
                        }
                        $Result += ( $NodeData );
                    }
            }

            Write-Host "Specific Node Data Collected from SQL..." -ForegroundColor Green;

            # Format the $Result Array
            $Config = [PSCustomObject]@{ "AllNodes" = ( [system.Array]$Result ) };

            Write-Host "Formatting Data and Outputting JSON Configuration File to: $DSCConfigurationDataFile" -ForegroundColor Green;

            # Output the Config Array as a JSON Object to the Output file
            $Config | ConvertTo-JSON -Depth 3 | Out-File $DSCConfigurationDataFile

        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

Function ConvertCIDRToClassless
{

    [string]$ClusterCIDR;

    [int64]$Int64 = [convert]::ToInt64(('1' * $ClusterCIDR + '0' * (32 - $ClusterCIDR)), 2);

    return '{0}.{1}.{2}.{3}' -f ([math]::Truncate($Int64 / 16777216)).ToString(), `
                                ([math]::Truncate(($Int64 % 16777216) / 65536)).ToString(), `
                                ([math]::Truncate(($Int64 % 65536)/256)).ToString(), `
                                ([math]::Truncate($Int64 % 256)).ToString();

}

Function Add-MultiSubnetClusterIPAddress
{
    param ( [string]$DSCConfigurationDataFile )

    Try
        {
            # Import the DSC Configuration File
            ( $DSCConfigurationData, $DSCPullServerURL, $DSCComplianceServerURL, $DSCConfigurationFileDir, $DSCImageSource, ` 
              $SQLVersion, $SQLInstanceName, $SQLInstallDataDir, $SQLInstallSource, $CertificateFile, `
              $PFXFile, $PFXPassword, $Thumbprint, $ClusterName, $TargetOU, $Cluster_IPAddress1, `
              $PrimaryNode ) = Import-DSCConfigurationFromJSON -DSCConfigurationDataFile $DSCConfigurationDataFile;
            Write-Host "DSC Build Configuration Data Loaded." -ForegroundColor Green;

            # Get the Cluster IP Addresses from the Data File
            $ClusterName        = $DSCConfigurationData.AllNodes.Cluster_Name;
            $Cluster_IPAddress1 = $DSCConfigurationData.AllNodes.Cluster_IPAddress1;
            $Cluster_IPAddress2 = $DSCConfigurationData.AllNodes.Cluster_IPAddress2;

            $split              = $Cluster_IPAddress1.split('/');
            $ClusterIP1         = $split[0];
            $ClusterCIDR        = $split[1];
            $ClusterSubnet1     = ConvertCIDRToClassless -ClusterCIDR $ClusterCIDR;


            $split              = $Cluster_IPAddress2.split('/');
            $ClusterIP2         = $split[0];
            $ClusterCIDR        = $split[1];
            $ClusterSubnet2     = ConvertCIDRToClassless -ClusterCIDR $ClusterCIDR;


            # We need to determine which IP Address is present, and add the second one
            $ClusterIPAddress = Get-ClusterResource -Cluster $ClusterName -Name "Cluster IP Address" | Get-ClusterParameter -Name Address
            $ClusterIPSubnetMask = Get-ClusterResource -Cluster $ClusterName -Name "Cluster IP Address" | Get-ClusterParameter -Name SubnetMask


            Add-ClusterResource -Cluster $ClusterName -Group "Cluster Group" -Name "Cluster IP Address 2" -ResourceType "IP Address";
            $IPResource = Get-ClusterResource -cluster $ClusterName "Cluster IP Address 2"


            If ( $Cluster_IPAddress1 -Match $ClusterIPAddress.Value )
                {

                $param1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPResource,Address,$ClusterIP2;
                $param2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPResource,SubnetMask,$ClusterSubnet2[1];

                }

            If ( $Cluster_IPAddress2 -Match $ClusterIPAddress.Value )
                {

                $param1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPResource,Address,$ClusterIP1;
                $param2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPResource,SubnetMask,$ClusterSubnet1[1];

                }

            $AllParams = $param1,$param2;
            $AllParams | Set-ClusterParameter -Cluster $ClusterName;

            Set-ClusterResourceDependency -Cluster $ClusterName -Resource "Cluster Name" -Dependency "[Cluster IP Address] or [Cluster IP Address 2]";

        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

Function Create-FileShareWitnessWithPermissions
{
    param ( [string]$ClusterName, [string]$Cluster_FSW_Base )

    Try
        {

            ( $Junk1 , $Junk2, $FileServer, $FileShare ) = $Cluster_FSW_Base.split('\\');
            $FileShare = $FileShare + $ClusterName;
            $LocalDrive = "D:";
            $FileDrive = $LocalDrive.replace(":", "`$\");


            # Make the folder 
            $FullPath= "\\" + $FileServer + "\" + $FileDrive + $FileShare;
            $LocalPath= $LocalDrive + "\" + $FileShare;
            if(![System.IO.Directory]::Exists($FullPath))
                {
                    # file with path $path doesn't exist
                    mkdir $FullPath;
                }


            # Create the File Share 
            (get-wmiobject -list -ComputerName $FileServer | Where-Object -FilterScript {$_.Name -eq "Win32_Share"}).InvokeMethod("Create",($LocalPath,$FileShare,0,100,"My Directory")) | Out-Null;


            # Assign the NTFS Permissions to Administrators
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow");
            $ACL=get-acl \\$FileServer\$FileShare;
            $ACL.SetAccessRule($AccessRule)
            set-acl \\$FileServer\$FileShare -AclObject $acl

            # Remove “Everyone” from Share permissions and assign the Share Permissions to “Administrators”
            Revoke-SmbShareAccess -name $FileShare -CimSession $FileServer -AccountName Everyone -Force | Out-Null;
            Grant-SmbShareAccess -name $FileShare -CimSession $FileServer -AccountName Administrators -AccessRight Full –Force | Out-Null;
            Grant-SmbShareAccess -name $FileShare -CimSession $FileServer -AccountName "CYMRU\gighsw_dataadmins" -AccessRight Full –Force | Out-Null;

            # Add the Cluster Account into the SMB share
            Write-Host "Granting $ClusterName Premissions to Access the UNC: \\$FileServer\$FileShare." -ForegroundColor Green;
            $AccountName = "CYMRU\" + $ClusterName + "`$";
            Grant-SmbShareAccess -name $FileShare -CimSession $FileServer -AccountName $AccountName -AccessRight Full –Force | Out-Null;

        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Check-CertificateAlreadyInstalled
{
    param ( [string]$TargetNodeName, [string]$Thumbprint )

    Try
        {
            # Grab all of the Certificates from the Remote Machine
            $RemoteCertificates = Invoke-Command { Get-ChildItem Cert:\LocalMachine\My } -ComputerName $TargetNodeName;

            foreach ( $RemoteCertificate in $RemoteCertificates )
                {
                    if ( $RemoteCertificate.Thumbprint -eq $Thumbprint )
                        {
                            return $true;
                        }
                }
            return $false;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}
