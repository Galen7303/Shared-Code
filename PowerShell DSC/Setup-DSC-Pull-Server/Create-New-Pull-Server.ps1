Configuration NewPullServer {
    param (
        [String[]]$ComputerName = 'localhost'
    )

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource –ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion="8.0.0.0"};

Node $ComputerName {
    WindowsFeature DSCServiceFeature {
        Ensure = "Present"
        Name = "DSC-Service"
    }

    xDSCWebService PSDSCPullServer {
        Ensure                  = "Present"
        EndpointName            = "PSDSCPullServer"
        Port                    = 8080
        PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
        CertificateThumbprint   = "4FCB91A28506FB6AA12C716EF53B3ADAD3F79D4D"
        ModulePath              = "$ev:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
        ConfigurationPath       = "C:\Program Files\WindowsPowerShell\Configuration"
        State                   = "Started"
        UseSecurityBestPractices = $false
        DependsOn               = "[WindowsFeature]DSCServiceFeature"
    }

    xDscWebService PSDSCComplianceServer {
        Ensure                  = "Present"
        EndpointName            = "PSDSCComplianceServer"
        Port                    = 9080
        PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
        CertificateThumbprint   = "4FCB91A28506FB6AA12C716EF53B3ADAD3F79D4D"
        State                   = "Started"
        #IsComplianceServer      = $true
        UseSecurityBestPractices = $false
        DependsOn               = ("[WindowsFeature]DSCServiceFeature")
    }
  }
}

#######################################################################################################################
#
#                    MAIN
#
#######################################################################################################################

# Before we Call the DSC Configuration Block to install the DSC Web Services, we need to:
# 1) Install the Certificate which we will be using
# 2) Install the Windows Feature for DSC
# 3) Configure WinRM
# All of these can be done through PowerShell...
# Install Certificate and PFX file
# Make sure this is Run Administrator



#######################################################################################################################
#
# Install the Certificate to be Used
#
#######################################################################################################################
clear;
$CertShare = 'D:\DSC Scripts\DSC-Certificate';
$CertFile = 'DSCPublicKey.cer';
$PFXFile = 'DSCPrivateKey.pfx';
$PFXPassword = 'M$$QL$3RV3R';

$CertLocation = Join-Path -Path $CertShare -ChildPath $CertFile;
$PFXLocation = Join-Path -Path $CertShare -ChildPath $PFXFile;


$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
if ( $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) -eq $true )
	{
	$Target = [System.Net.Dns]::GetHostName();
	
	Import-Certificate -CertStoreLocation Cert:\LocalMachine\My -FilePath $CertLocation;

	Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -FilePath $PFXLocation -Password (ConvertTo-SecureString -String $PFXPassword -AsPlainText -Force);

	}
else
	{
        Write-Host "Please Run as ADMINISTRATOR";
		exit 0;
	}


#######################################################################################################################
#
# Install the DSC Windows Feature
#
#######################################################################################################################
Install-WindowsFeature DSC-Service


#######################################################################################################################
#
# Configure WinRM for Remote Management
#
#######################################################################################################################
WinRM QuickConfig


#######################################################################################################################
#
# Call DSC to Configure the localmachine for the DSC Web Services
#
#######################################################################################################################
NewPullServer
Start-DscConfiguration .\NewPullServer -Wait