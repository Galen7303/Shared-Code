###############################################################################################################
#                                                                                                             #
# DSC Script to Build the Cluster and Availability Group                                                      #
#                                                                                                             #
###############################################################################################################
Configuration BuildCluster
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
    }

}
