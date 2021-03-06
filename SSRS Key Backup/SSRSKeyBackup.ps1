﻿###############################################################################################################
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
    param ( [Parameter(Position=0,mandatory=$true)] [string]$ModuleName )
    

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

function BackUp-SSRSKey
{
    param ( [Parameter(Position=0,mandatory=$true)] [string]$SourceServer,
            [Parameter(Position=1,mandatory=$true)] [string]$SourceSSRSInstance,
            [Parameter(Position=2,mandatory=$true)] [string]$SourceSSRSPort,
            [Parameter(Position=3,mandatory=$true)] [string]$ReportServerVersion,
            [Parameter(Position=4,mandatory=$true)] [string]$KeyPath,
            [Parameter(Position=5,mandatory=$true)] [string]$KeyPassword )

    Try
        {
            # Connect to the Source and Backup the Key

            if ( $SourceSSRSInstance -ne $null )
                {
                    $ReportServerUri = 'http://' + $SourceServer + ':' + $SourceSSRSPort + '/ReportServer_' + $SourceSSRSInstance + '/ReportService2010.asmx?wsdl';
                }
            else
                {
                    $ReportServerUri = 'http://' + $SourceServer + ':' + $SourceSSRSPort + '/ReportServer/ReportService2010.asmx?wsdl';
                }


            Connect-RsReportServer `
                -ComputerName $SourceServer `
                -ReportServerInstance $SourceSSRSInstance `
                -ReportServerUri $ReportServerUri `
                -ReportServerVersion $ReportServerVersion;

            Backup-RSEncryptionKey -Password $KeyPassword -KeyPath $KeyPath;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Check-KeyFileCreated
{
    param ( [string]$KeyPath )

    Try
        {
            if ( Test-Path $KeyPath -Pathtype Leaf )
                {
                    Write-Host "Reporting Services Key Backed Up Successfully to $KeyPath" -ForegroundColor Green;
                }
            else
                {
                    Write-Host "Reporting Services Key did not backup correctly...." -ForegroundColor Red;
                    exit 1;
                }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Restore-SSRSKey
{
    param ( [Parameter(Position=0,mandatory=$true)] [string]$DestinationServer,
            [Parameter(Position=1,mandatory=$true)] [string]$DestinationSSRSInstance,
            [Parameter(Position=2,mandatory=$true)] [string]$DestinationSSRSPort,
            [Parameter(Position=3,mandatory=$true)] [string]$ReportServerVersion,
            [Parameter(Position=4,mandatory=$true)] [string]$KeyPath,
            [Parameter(Position=5,mandatory=$true)] [string]$KeyPassword )

    Try
        {
            # Connect to the Destination and Restore the Key

            if ( $DestinationSSRSInstance -ne $null )
                {
                    $ReportServerUri = 'http://' + $DestinationServer + ':' + $DestinationSSRSPort + '/ReportServer_' + $DestinationSSRSInstance + '/ReportService2010.asmx?wsdl';
                }
            else
                {
                    $ReportServerUri = 'http://' + $DestinationServer + ':' + $DestinationSSRSPort + '/ReportServer/ReportService2010.asmx?wsdl';
                }


            Connect-RsReportServer `
                -ComputerName $DestinationServer `
                -ReportServerInstance $DestinationSSRSInstance `
                -ReportServerUri $ReportServerUri `
                -ReportServerVersion $ReportServerVersion;

            Restore-RSEncryptionKey -Password $KeyPassword -KeyPath $KeyPath;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

###############################################################################################################
#                                                                                                             #
# Main Code Execution Starts Here                                                                             #
#                                                                                                             #
###############################################################################################################

Load-PSModule -ModuleName ReportingServicesTools;
# If the ReportingServicesTools are not installed, they can be by:
# Install-Module -Name ReportingServicesTools -RequiredVersion 0.0.4.6
# Alternatively, the module can be downloaded by:
# Save-Module -Name ReportingServicesTools -Path <path>

$SourceServer = ".";
$SourceSSRSInstance = "SQL2016INST1";
$SourceSSRSPort = "80";
$DestinationServer = "Test1";
$DestinationSSRSInstance = "SQL2016INST1";
$DestinationSSRSPort = "80";
$ReportServerVersion = "SQLServer2016"; # Could be SQLServer2012 | SQLServer2014 | SQLServer2016 | SQLServer2017

$KeyPassword = "P@ssw0rd!";
$LocalKeyPath = "C:\Temp\SSRSKey.snk";


# Check the Servers are local
if ( $SourceServer -eq "." )
    {
        $SourceServer = $env:COMPUTERNAME;
    }
if ( $DestinationServer -eq "." )
    {
        $DestinationServer = $env:COMPUTERNAME;
    }

# Connect to the SSRS Instance and Backup the Encryption Key
BackUp-SSRSKey `
    -SourceServer $SourceServer `
    -SourceSSRSInstance $SourceSSRSInstance `
    -SourceSSRSPort $SourceSSRSPort `
    -ReportServerVersion $ReportServerVersion `
    -KeyPath $LocalKeyPath `
    -KeyPassword $KeyPassword;


# Check we did actually manage to produce a keyfile
Check-KeyFileCreated -KeyPath $LocalKeyPath;

# Might need to move the file from Source to Desintation Server
$UNCKeyPath = Join-Path -Path '\\' -ChildPath (Join-Path -Path $SourceServer -ChildPath $LocalKeyPath.Replace(':', '$'));

# Connect to the Destination and Restore the Key
Restore-SSRSKey `
    -DestinationServer $DestinationServer `
    -DestinationSSRSInstance $DestinationSSRSInstance `
    -DestinationSSRSPort $DestinationSSRSPort `
    -ReportServerVersion $ReportServerVersion `
    -KeyPath $UNCKeyPath `
    -KeyPassword $KeyPassword;


# Remove the .SNK file from the filesystem
Remove-Item $LocalKeyPath -Force;