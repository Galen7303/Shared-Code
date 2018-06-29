###############################################################################################################
#                                                                                                             #
# DSC Script to Build the Cluster and Availability Group                                                      #
#                                                                                                             #
###############################################################################################################
Configuration BuildClusterAndSQLAvailabilityGroup
{

    # Install-Module xSQLServer -RequiredVersion 8.0.0.0 -Force
    # Installs the updated xSQLServer PowerShell module to C:\Program Files\WindowsPowerShell\Modules\xSQLServer\
    # Repackage into the C:\Program Files\WindowsPowerShell\DscService\Modules\ directory using steps outlined Publish-ModulesToPullServer.ps1
    # Finally, build a checksum for the new module using New-DSCChecksum 'C:\Program Files\WindowsPowerShell\DscService\Modules\'
    #
    Import-DscResource –ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion="8.0.0.0"};
	Import-DscResource -ModuleName @{ModuleName="xSQLServer";ModuleVersion="8.2.0.0"};
	Import-DscResource -ModuleName @{ModuleName="xNetworking";ModuleVersion="5.0.0.0"};
	Import-DscResource -ModuleName @{ModuleName="xFailOverCluster";ModuleVersion="1.7.0.0"};

    # Common Installation Steps for ALL nodes.    	
    Node $AllNodes.NodeName {		
        
        #############################################################
        #
        # Install the OS level Roles and Features needed for creating
        # a Windows Cluster and SQL Availability Group
        #
        #############################################################
        xWindowsFeatureSet WindowsFeatureSet1
        {
            Name                 = @( 'RSAT-AD-PowerShell', `
                                      'Failover-clustering', `
                                      'RSAT-Clustering-PowerShell', `
                                      'RSAT-Clustering-Mgmt', `
                                      'RSAT-Clustering-CmdInterface', `
                                      'Net-Framework-Core', `
                                      'Net-Framework-45-Core' );
            Ensure               = "Present";
            IncludeAllSubFeature = $true;

        }


        #############################################################
        #
        # Install SQL Server
        #
        #############################################################
        xSqlServerSetup installSqlServer
        {
            Action                       = "Install";
            AgtSvcAccount                = $sqlAgentCred;
            #ASBackupDir                 = ;
            #ASCollation                 = ;
            #ASConfigDir                 = ;
            #ASDataDir                   = ;
            #ASLogDir                    = ;
            ASSvcAccount                 = $SSASCred;
            #ASSysAdminAccounts          = ;
            #ASTempDir                   = ;
            #BrowserSvcStartupType       = ; 
            #ErrorReporting              = ;
            #FailoverClusterGroupName    = ;
            #FailoverClusterIPAddress    = ;
            #FailOverClusterNetworkName  = ;
            Features                     = $Node.SQL_FeatureList;
            #ForceReboot                 = ;
            #FTSvcAccount                = ;
            #InstallSharedDir            = ;
            #InstallSharedWOWDir         = ;
            InstallSQLDataDir            = $Node.SQL_InstallDataDir;
            #InstanceDir                 = ;
            #InstanceID                  = ;
            InstanceName                 = $Node.SQL_InstanceName;
            ISSvcAccount                 = $SSISCred;
            #ProductKey                  = ;
            PsDscRunAsCredential         = $DomainBuildCred;
            RSSvcAccount                 = $SSRSCred;
            SAPwd                        = $SACred;
            #SecurityMode                = $SecurityMode;
            SourceCredential             = $DomainBuildCred;
            SourcePath                   = $SQLInstallSource;
            #SQLBackupDir                = ;
            SQLCollation                 = $Node.SQL_Collation;
            SQLSvcAccount                = $sqlServiceCred;
            SQLSysAdminAccounts          = $Node.SQL_DBAGroup;
            SQLTempDBDir                 = $Node.SQL_TempDBDir;
            SQLTempDBLogDir              = $Node.SQL_TempDBLogDir;
            SQLUserDBDir                 = $Node.SQL_UserDBDir;
            SQLUserDBLogDir              = $Node.SQL_UserDBLogDir;
            #SQMReporting                = ;
            #SuppressReboot              = ;
            UpdateEnabled                = $false;
            #UpdateSource                = ;

            DependsOn                    = ("[xWindowsFeatureSet]WindowsFeatureSet1");
        }


        #############################################################
        #
        # Configure SQL Server
        #
        #############################################################
        xFireWall enableRemoteAccessOnSQLBrowser
        {

            Ensure     = "Present";
            Name       = "SqlBrowser";
            Enabled    = "True";
            Program    = Join-Path ${env:ProgramFiles(x86)} -ChildPath "Microsoft SQL Server\90\Shared\sqlbrowser.exe";
            Profile    = "Any";

            DependsOn  = "[xSqlServerSetup]installSqlServer";
        }

        xFirewall enableInBoundRemoteAccessOnSQLServer
        {

            Ensure          = "Present";
            Name            = "InBound SQL Server Windows NT - 64 Bit";
            DisplayName     = "InBound Firewall Rule for SQL Server";
            Description     = "InBound Firewall Rule for SQL Server";
            Direction       = "InBound";
            Program         = "$SQLProgram"
            Enabled         = "True";
            Profile         = "Any";
            Protocol        = "Any";
            RemotePort      = "Any";
            LocalPort       = "Any";

            DependsOn = "[xSqlServerSetup]installSqlServer";
        }

        xFirewall enableOutBoundRemoteAccessOnSQLServer
        {

            Ensure        = "Present";
            Name          = "OutBound SQL Server Windows NT - 64 Bit";
            DisplayName   = "OutBound Firewall Rule for SQL Server";
            Description   = "OutBound Firewall Rule for SQL Server";
            Direction     = "OutBound";
            Program       = "$SQLProgram"
            Enabled       = "True";
            Profile       = "Any";
            RemotePort    = "Any";
            LocalPort     = "Any";
            Protocol      = "Any";

            DependsOn     = "[xSqlServerSetup]installSqlServer";
        }
	
        xSQLServerMemory ConfigureSQLMemory
        {
            Ensure            = "Present";
            DynamicAlloc      = $false;
            MinMemory         = $Node.SQL_MinServerMemory;
            MaxMemory         = $Node.SQL_MaxServerMemory;
           	SQLServer         = $Node.NodeName;
			SQLInstanceName   = $Node.SQL_InstanceName;

            DependsOn         = "[xSqlServerSetup]installSqlServer";
        }

        xSQLServerMaxDop  ConfigureSQLMaxDop
        {
            Ensure            = "Present";
            DynamicAlloc      = $false;
            MaxDop            = $Node.SQL_ServerMaxDop;
			SQLServer         = $Node.NodeName;
			SQLInstanceName   = $Node.SQL_InstanceName;

            DependsOn         = "[xSqlServerSetup]installSqlServer";
        }
        
        xSQLServerLogin AddServiceAccount 
        { 
            Ensure               = "Present"; 
            Name                 = $sqlServiceCred.UserName;
            LoginType            = "WindowsUser"; 
            SQLServer            = $Node.NodeName; 
            SQLInstanceName      = $Node.SQL_InstanceName; 
            PsDscRunAsCredential = $DomainBuildCred; 

            DependsOn            = "[xSqlServerSetup]installSqlServer";
        }

        xSQLServerLogin AddNTServiceClusSvc 
        { 
            Ensure               = "Present"; 
            Name                 = "NT SERVICE\ClusSvc"; 
            LoginType            = "WindowsUser"; 
            SQLServer            = $Node.NodeName; 
            SQLInstanceName      = $Node.SQL_InstanceName; 
            PsDscRunAsCredential = $DomainBuildCred; 

            DependsOn            = "[xSqlServerSetup]installSqlServer";
        } 
 
        xSQLServerPermission AddNTServiceClusSvcPermissions 
        { 

            Ensure               = "Present"; 
            NodeName             = $Node.NodeName;
            InstanceName         = $Node.SQL_InstanceName; 
            Principal            = "NT SERVICE\ClusSvc"; 
            Permission           = "AlterAnyAvailabilityGroup", "ViewServerState"; 
            PsDscRunAsCredential = $DomainBuildCred; 

            DependsOn            = "[xSQLServerLogin]AddNTServiceClusSvc"; 
        } 

        xSQLServerLogin DisableSAccount
        {
            Name            = "sa";
            LoginType       = "SqlLogin";
            SQLServer       = $Node.NodeName
            SQLInstanceName = $Node.SQL_InstanceName;
            Disabled        = $true;

            DependsOn       = "[xSqlServerSetup]installSqlServer";
        }

        xSQLServerEndpoint ConfigureSQLEndPoint
        {
			Ensure          = "Present";
            SQLServer       = $Node.NodeName;
			SQLInstanceName = $Node.SQL_InstanceName;
			Port            = $Node.AG_ReplicaPort;
			EndPointName    = $Node.AG_EndPointName;
			
    		DependsOn       = "[xSqlServerSetup]installSqlServer";	
            
        }

        xSQLServerEndpointPermission ConfigureSQLEndPointPermission
        {
            Ensure          = "Present";
            NodeName        = $Node.NodeName;
			InstanceName    = $Node.SQL_InstanceName;
            Permission      = "CONNECT";
            Principal       = $sqlServiceCred.UserName;
            Name            = $Node.AG_EndPointName;

            DependsOn       = ("[xSQLServerEndpoint]ConfigureSQLEndPoint","[xSQLServerLogin]AddServiceAccount");
        }
}

    # Installation steps for only the Primary node
    Node $AllNodes.Where{$_.Role -eq "PrimaryNode" }.NodeName {
        
        # Create the underlying Windows Cluster
        xCluster createOrJoinCluster
        {
            Name                          = $Node.Cluster_Name;
            StaticIPAddress               = $Node.Cluster_IPAddress1;
            DomainAdministratorCredential = $DomainBuildCred;

        }

        xClusterQuorum SetQuorumToNodeAndFileShareMajority
        {
            IsSingleInstance              = 'Yes';
            Type                          = 'NodeAndFileShareMajority';
            Resource                      = $Node.Cluster_FSW_Base + $Node.Cluster_Name;

        }

        xSQLServerAlwaysOnService ConfigureSQLService
        {
			Ensure             = "Present";
			SQLServer          = $Node.NodeName;
			SQLInstanceName    = $Node.SQL_InstanceName;
			
            DependsOn = "[xCluster]createOrJoinCluster";
 
		}

        xSQLServerAlwaysOnAvailabilityGroup createOrJoinHAG
        {
			Ensure               = "Present";
			Name                 = $Node.AG_Name;
			SQLInstanceName      = $Node.SQL_InstanceName;
            SQLServer            = $Node.NodeName;
			PsDscRunAsCredential = $DomainBuildCred;
            
            DependsOn            = "[xSQLServerEndpointPermission]ConfigureSQLEndPointPermission";
        } 

        
        xSQLServerAvailabilityGroupListener CreateAGListener
        {
            Ensure               = "Present";
            InstanceName         = $Node.SQL_InstanceName;
            NodeName             = $Node.NodeName;
            Name                 = $Node.AG_Listener;
            AvailabilityGroup    = $Node.AG_Name;
            IpAddress            = @($Node.AG_IPAddress1, `
                                     $Node.AG_IPAddress2);
            Port                 = $Node.AG_ClientPort;
            DHCP                 = $false;
            PsDscRunAsCredential = $DomainBuildCred;

            DependsOn            = "[xSQLServerAlwaysOnAvailabilityGroup]createOrJoinHAG";

        }

        xSQLServerDatabase CreateDatabase
            {
                Ensure           = "Present";
                Name             = $Node.AG_Databases
                SQLServer        = $Node.NodeName
                SQLInstanceName  = $Node.SQL_InstanceName

                DependsOn        = "[xSQLServerAlwaysOnAvailabilityGroup]createOrJoinHAG";

            }


        xSQLServerAlwaysOnAvailabilityGroupDatabaseMembership PutDBInAG
            {
                Ensure                = "Present";
                AvailabilityGroupName = $Node.AG_Name;
                BackupPath            = $Node.SQL_DBBackupLocation;
                DatabaseName          = $Node.AG_Databases;
                SQLInstanceName       = $Node.SQL_InstanceName;
                SQLServer             = $Node.NodeName;
                PsDscRunAsCredential  = $DomainBuildCred;
        
                DependsOn             = "[xSQLServerDatabase]CreateDatabase";
        
            }

    }

    # Installation steps for any Secondary node
    Node $AllNodes.Where{ $_.Role -eq "SecondaryNode" }.NodeName {
      
        
        # Join Cluster
        xWaitForCluster waitForCluster
        {
            Name             = $Node.Cluster_Name;
            RetryIntervalSec = 10;
            RetryCount       = 60;

        }

        xCluster joinCluster
        {
            Name                          = $Node.Cluster_Name;
            StaticIPAddress               = $Node.Cluster_IPAddress1;
            DomainAdministratorCredential = $DomainBuildCred;

            DependsOn                     = "[xWaitForCluster]waitForCluster";
        }

        xSQLServerAlwaysOnService ConfigureSQLService
        {
			Ensure          = "Present";
			SQLServer       = $Node.NodeName;
			SQLInstanceName = $Node.SQL_InstanceName;
			
            DependsOn       = "[xCluster]joinCluster";

		}
       
        xWaitForAvailabilityGroup waitForHAG
        {
            Name             = $Node.AG_Name;
            RetryIntervalSec = 10;
            RetryCount       = 10;
            
            DependsOn        = "[xSQLServerEndpointPermission]ConfigureSQLEndPointPermission";
        }

        xSQLServerAlwaysOnAvailabilityGroupReplica AddAGReplica
        {
			Ensure                        = "Present";
            Name                          = "$($Node.NodeName)";
            AvailabilityGroupName         = $Node.AG_Name;
			SQLServer                     = $Node.NodeName;
            SQLInstanceName               = $Node.SQL_InstanceName;
            PrimaryReplicaSQLServer       = ( $AllNodes | where-Object { $_.Role -eq "PrimaryNode" }).NodeName;
            PrimaryReplicaSQLInstanceName = ( $AllNodes | where-Object { $_.Role -eq "PrimaryNode" }).SQL_InstanceName;
            PsDscRunAsCredential          = $DomainBuildCred;
            
            DependsOn                     = "[xWaitForAvailabilityGroup]waitForHAG";
        }

    }

}
