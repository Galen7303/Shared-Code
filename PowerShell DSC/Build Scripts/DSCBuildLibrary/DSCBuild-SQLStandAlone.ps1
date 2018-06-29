###############################################################################################################
#                                                                                                             #
# DSC Script to Build SQL Server                                                                              #
#                                                                                                             #
###############################################################################################################
Configuration BuildSQLServer
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
            Action                              = "Install";
            AgtSvcAccount                       = $sqlAgentCred;
            #ASBackupDir                        = ;
            #ASCollation                        = ;
            #ASConfigDir                        = ;
            #ASDataDir                          = ;
            #ASLogDir                           = ;
            #ASSvcAccount                       = ;
            #ASSysAdminAccounts                 = ;
            #ASTempDir                          = ;
            #BrowserSvcStartupType              = ; 
            #ErrorReporting                     = ;
            #FailoverClusterGroupName           = ;
            #FailoverClusterIPAddress           = ;
            #FailOverClusterNetworkName         = ;
            Features                            = $Node.SQL_FeatureList;
            #ForceReboot                        = ;
            #FTSvcAccount                       = ;
            #InstallSharedDir                   = ;
            #InstallSharedWOWDir                = ;
            InstallSQLDataDir                   = $Node.SQL_InstallDataDir;
            #InstanceDir                        = ;
            #InstanceID                         = ;
            InstanceName                        = $Node.SQL_InstanceName;
            #ISSvcAccount                       = ;
            #ProductKey                         = ;
            PsDscRunAsCredential                = $DomainBuildCred;
            #RSSvcAccount                       = ;
            SAPwd                               = $SACred;
            #SecurityMode                       = $SecurityMode;
            SourceCredential                    = $DomainBuildCred;
            SourcePath                          = $SQLInstallSource;
            #SQLBackupDir                       = ;
            SQLCollation                        = $Node.SQL_Collation;
            SQLSvcAccount                       = $sqlServiceCred;
            SQLSysAdminAccounts                 = $Node.SQL_DBAGroup;
            SQLTempDBDir                        = $Node.SQL_TempDBDir;
            SQLTempDBLogDir                     = $Node.SQL_TempDBLogDir;
            SQLUserDBDir                        = $Node.SQL_UserDBDir;
            SQLUserDBLogDir                     = $Node.SQL_UserDBLogDir;
            #SQMReporting                       = ;
            #SuppressReboot                     = ;
            UpdateEnabled                       = $false;
            #UpdateSource                       = ;

            DependsOn                           = ("[xWindowsFeatureSet]WindowsFeatureSet1");
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

        xSQLServerLogin DisableSAccount
        {
            Name            = "sa";
            LoginType       = "SqlLogin";
            SQLServer       = $Node.NodeName
            SQLInstanceName = $Node.SQL_InstanceName;
            Disabled        = $true;

            DependsOn       = "[xSqlServerSetup]installSqlServer";
        }
    }
}
