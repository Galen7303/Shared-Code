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

function Get-SQLEnvironment
{
    param ( [string]$ServerName )

    Try
        {
            
 
            $SqlQuery = "SELECT
	                     CONVERT(char(80), SERVERPROPERTY('servername')) AS [ServerName],
	                     CONVERT(char(80), SERVERPROPERTY('InstanceName')) AS [InstanceName],
	                     CONVERT(char(40), SERVERPROPERTY('ComputerNamePhysicalNetBIOS')) AS [Hostname], 
	                     CONVERT(char(1), SERVERPROPERTY('IsClustered')) AS [Clustered],
	                     CASE
		                     WHEN SERVERPROPERTY('IsClustered') = 1 THEN 
			                     SERVERPROPERTY('MachineName') 
		                     ELSE
			                     NULL
	                     END AS [ClusterName],
	                     CONVERT(char(1), SERVERPROPERTY('IsHadrEnabled')) AS [HADR]";
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = “Server=$ServerName;Database=master;Integrated Security=True”;
            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand;
            $SqlCmd.CommandText = $SqlQuery;
            $SqlCmd.Connection = $SqlConnection;
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter;   
            $SqlAdapter.SelectCommand = $SqlCmd;
            $DataSet = New-Object System.Data.DataSet;
            
            try
                {
                    $SqlAdapter.Fill($DataSet);
                }
            catch
                {
                    Write-Host "Connection to $ServerName Unsuccessful." -ForegroundColor Red;
                    exit(0);
                }
            $SqlConnection.Close();
 
            return ($DataSet);
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Get-SQLAGEnvironment
{
    param ( [string]$ServerName , [string]$AGName )

    Try
        {
            $SqlQuery = "DECLARE @AGName VARCHAR(64) = '" + $AGName + "';
                        SELECT
	                        UPPER(ar.replica_server_name) AS [Name],
	                        'node' AS [Role]
                        FROM
	                        sys.availability_group_listeners agl
                        INNER JOIN sys.availability_groups ags
                        ON ags.group_id = agl.group_id
                        INNER JOIN sys.availability_replicas ar
                        ON ar.group_id = ags.group_id
                        WHERE
	                        ags.name = @AGName
                        UNION
                        SELECT
	                        UPPER(agl.dns_name) AS [DNS],
	                        'listener' AS [Role]
                        FROM
	                        sys.availability_group_listeners agl
                        INNER JOIN sys.availability_groups ags
                        ON ags.group_id = agl.group_id
                        INNER JOIN sys.availability_replicas ar
                        ON ar.group_id = ags.group_id
                        WHERE
	                        ags.name = @AGName";
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = “Server=$ServerName;Database=master;Integrated Security=True”;
            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand;
            $SqlCmd.CommandText = $SqlQuery;
            $SqlCmd.Connection = $SqlConnection;
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter;   
            $SqlAdapter.SelectCommand = $SqlCmd;
            $DataSet = New-Object System.Data.DataSet;
            
            try
                {
                    $SqlAdapter.Fill($DataSet);
                }
            catch
                {
                    Write-Host "Connection to $ServerName Unsuccessful." -ForegroundColor Red;
                    exit(0);
                }
            $SqlConnection.Close();
 
            return ($DataSet);
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Get-SQLServiceInfo
{
    param ( [string]$ServerName )

    Try
        {
            
 
            $SqlQuery = "set nocount on
                         DECLARE @key VARCHAR(100)
                         DECLARE @PortNumber VARCHAR(20)
                         DECLARE @ServiceAccount VARCHAR(64)

                         IF CHARINDEX('\',CONVERT(char(20), SERVERPROPERTY('servername')),0) <>0
                             BEGIN
                                 SET @key = 'SOFTWARE\MICROSOFT\Microsoft SQL Server\'+@@servicename+'\MSSQLServer\Supersocketnetlib\TCP'
                             END
                         ELSE
                             BEGIN
                                 SET @key = 'SOFTWARE\MICROSOFT\MSSQLServer\MSSQLServer\Supersocketnetlib\TCP'
                             END
                         EXEC MASTER..xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@key,@value_name='Tcpport',@value=@PortNumber OUTPUT

                         SELECT
	                         @ServiceAccount = service_account
                         FROM
	                         sys.dm_server_services
                         WHERE ServiceName like 'SQL Server (%'
 
                         SELECT
	                         @ServiceAccount AS ServiceAccount,
                             CONVERT(varchar(10),@PortNumber) AS PortNumber";
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = “Server=$ServerName;Database=master;Integrated Security=True”;
            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand;
            $SqlCmd.CommandText = $SqlQuery;
            $SqlCmd.Connection = $SqlConnection;
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter;   
            $SqlAdapter.SelectCommand = $SqlCmd;
            $DataSet = New-Object System.Data.DataSet;
            
            try
                {
                    $SqlAdapter.Fill($DataSet);
                }
            catch
                {
                    Write-Host "Connection to $ServerName Unsuccessful." -ForegroundColor Red;
                    exit(0);
                }
            $SqlConnection.Close();
 
            return ($DataSet);
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Get-NodeSPNs
{
    param ( [string]$Servername , [string]$TCPPort )

    Try
        {

            # Get the Host's FQDN
            ( $HostName, $InstanceName ) = $ServerName.split('\');
            $HostObject = [System.Net.Dns]::GetHostByName( $HostName );
            $HostFQDN = $HostObject.Hostname;

            # https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/register-a-service-principal-name-for-kerberos-connections
            # For a TCP/IP connection the SPN is registered in the format 
            # MSSQLSvc/<FQDN>:<tcpport>.
            # Both named instances and the default instance are registered as MSSQLSvc, 
            # relying on the <tcpport> value to differentiate the instances. 

            # For other connections that support Kerberos the SPN is registered in the format 
            # MSSQLSvc/<FQDN>:<instancename> for a named instance. 
            # The format for registering the default instance is MSSQLSvc/<FQDN>.

            If ( $InstanceName -eq $null )
                {
                    # Default instance using TCP/IP
                    # MSSQLSvc/<FQDN>:<port>
                    $NodeSPNs.Add('MSSQLSvc/' + $HostFQDN + ':' + $TCPPort) | Out-Null;

                    # Default instance NOT using TCP/IP
                    # MSSQLSvc/<FQDN>
                    $NodeSPNs.Add('MSSQLSvc/' + $HostFQDN) | Out-Null; 

                }
            else
                {
                    # Named instance using TCP/IP
                    # MSSQLSvc/<FQDN>:<port>
                    $NodeSPNs.Add('MSSQLSvc/' + $HostFQDN + ':' + $TCPPort) | Out-Null;  

                    # Named instance NOT using TCP/IP
                    # MSSQLSvc/<FQDN>:[<port> | <instancename>]
                    $NodeSPNs.Add('MSSQLSvc/' + $HostFQDN + ':' + $InstanceName) | Out-Null; 
                }


                return ( $NodeSPNs );
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Get-ExistingSPNs
{
    param ( [System.Collections.ArrayList]$ExistingSPNs, [string]$Domain, [string]$ServiceAccount, [string]$Hostname)

    Try
        {
            if ( $Domain -eq "NT Service" )
                {   # SQL Server Running under a local System Account
                    $ADObject = Get-ADComputer -LDAPFilter "(SamAccountname=$Hostname`$)" `
                                         -Properties name, serviceprincipalname `
                                         -ErrorAction Stop;
                }
            else
                {   # SQL Server Running Under a Domain Account
                    $ADObject = Get-ADUser -LDAPFilter "(SamAccountname=$ServiceAccount)" `
                                         -Properties name, serviceprincipalname `
                                         -ErrorAction Stop;
                }


            Foreach ( $SPN in $ADObject.serviceprincipalname | where { $_ -match "MSSQLSvc" } )
                {
                    $ExistingSPNs.Add($SPN) | Out-Null;
                }

            return ( ,$ExistingSPNs );
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Add-MissingSPNs
{
    param ( [System.Collections.ArrayList]$MissingSPNs, [string]$Domain, [string]$ServiceAccount, [string]$Hostname, [PSCredential]$DomainAdminCred )

    Try
        {
             if ( $Domain -eq "NT Service" )
                {   # SQL Server Running under a local System Account
                    $ADObject = Get-ADComputer -LDAPFilter "(SamAccountname=$Hostname`$)" `
                                         -Properties name, serviceprincipalname `
                                         -ErrorAction Stop;
                }
            else
                {   # SQL Server Running Under a Domain Account
                    $ADObject = Get-ADUser -LDAPFilter "(SamAccountname=$ServiceAccount)" `
                                         -Properties name, serviceprincipalname `
                                         -ErrorAction Stop;
                }

            $DN = $ADUserObject.DistinguishedName
            
            # Take the SPNs which are missing and add them to AD
            for ( $index = 0; $index -lt ( $MissingSPNs.Count ); $index++ )
                {
                    try
                        {   
                            $SPN = $MissingSPNs[$index];
                            Set-ADObject `
                                -Identity $DN `
                                -add @{ serviceprincipalname=$SPN } `
                                -Credential $DomainAdminCred `
                                -ErrorVariable SPNerror `
                                -ErrorAction SilentlyContinue 
                        } 
                    Catch [exception] 
                        {
                            Write-Host "An error occured while modifying $ServiceAccountName. Error details: $($_.Exception.Message) " -ForegroundColor Red 
                        }
                }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Check-NodeAccountsAreTheSame
{
    param ( [string]$NodeAccount )

    Try
        {
            $ArrayElementCount = $NodeAccount | select -uniq
            
            # If there is only 1 unique element in the array
            # the Service Accounts must be all the same
            # which is what we need
            if ( $ArrayElementCount.Count -eq 1 )
                {
                    return ($true)
                }
            else
                {
                    return ($false)
                }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}
