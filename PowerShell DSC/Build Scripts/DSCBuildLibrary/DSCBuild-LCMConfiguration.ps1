###############################################################################################################
#                                                                                                             #
# Configure the DSC Configuration Manager on the Target VMs                                                   #
#                                                                                                             #
###############################################################################################################
[DSCLocalConfigurationManager()]
Configuration SetPullMode
{
	param
		(
			[Parameter(Mandatory)]
			[string]$guid,

			[Parameter(Mandatory)]
			[string]$TargetNodeName,
			
			[Parameter(Mandatory)]
			[string]$DSCPullServerURL,

			[Parameter(Mandatory)]
			[string]$Thumbprint,

			[Parameter(Mandatory)]
			[string]$DSCComplianceServerURL
		)
	
	Node $TargetNodeName {
		Settings
			{
	 			RefreshMode = "Pull";
				ConfigurationID = $guid;
	 			ConfigurationMode = "ApplyAndMonitor";   #'ApplyOnly', 'ApplyAndAutocorrect', 'ApplyAndMonitor'
				RefreshFrequencyMins = 30;
				RebootNodeIfNeeded = $true;
				AllowModuleOverWrite = $true;
				DebugMode = 'All';
				CertificateID = $Thumbprint;
			}
			ConfigurationRepositoryWeb DSCMaster-PullServer
				{
					ServerUrl               = $DSCPullServerURL;
					AllowUnsecureConnection = $true;
				}

            ReportServerWeb DSCMaster-ComplianceServer
                {
                    ServerURL               = $DSCComplianceServerURL;
                    AllowUnsecureConnection = $true;
				}
			
 		}
 } 
