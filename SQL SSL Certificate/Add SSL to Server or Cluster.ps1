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
			Exit 1;
		}
}

function Install-SQLCertificate
{
    param ( [string]$TargetNodeName, [string]$InstanceName, [string]$Thumbprint, [PSCredential]$Credential )

    Try
        {
            
            $registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceName\MSSQLServer\SuperSocketNetLib\";

            $ScriptCommand = "Set-ItemProperty -path $registryPath -name Certificate -value $Thumbprint";
            
            $CommandScriptBlock = [Scriptblock]::Create($ScriptCommand)

            Invoke-Command -ComputerName $TargetNodeName -ScriptBlock $CommandScriptBlock -Credential $Credential;

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
            # $Credential = Get-Credential -UserName "HSBC\BuildCredential" -Message "Enter the Domain Admin Account Details";
            $password = "P@ssw0rd1" | convertto-securestring -asPlainText -Force
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


##################################################################################################################
#
# Main Code Execution Starts Here
#
##################################################################################################################
#requires -version 4.0 
#requires –runasadministrator

Set-ExecutionPolicy unrestricted
Set-StrictMode -Version 1.0;

clear;


Load-PSModule failoverclusters;
Load-PSModule SQLPS; 

$Target = "MININT-435D8DN\SQL2016INST1";
$CertFile   = "\\servername\share\path_to_certificate.cer";
$PFXFile    = "\\servername\share\path_to_pfx_file.cer";


( $ServerName , $InstanceName ) = ($Target).split("\");
if ( $InstanceName -eq $null ) { $InstanceName = "MSSQLSERVER" };

$Credential = Get-BuildCredentials;

if ( Test-Path $CertFile )
    {
        $CertObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2;
        $CertObject.Import($CertificateFile);
        $Thumbprint = $CertObject.Thumbprint;
    }
else
    {
        Write-Host "$CertFile Does Not Exist..." -Foreground Red;
        Write-Host "Exiting..." -ForegroundColor Red;
        Exit 1;
    }

if ( -not ( Test-Path $PFXFile ))
    {
        Write-Host "$PFXFile Does Not Exist..." -Foreground Red;
        Write-Host "Exiting..." -ForegroundColor Red;
        Exit 1;
    }

# Determine if the machine is a cluster or a standlone
$WMIObj = Get-WMIObject -query "select * from Win32_ComputerSystem" -ComputerName $ServerName | select name
if ($WMIObj -ne $ServerName) 
    {
        Write-Output "$ServerName is clustered";
        $nodes = (Get-ClusterNode -Cluster $ServerName).name;
    } 
else 
    {
        Write-Output "$ServerName is not clustered";
        $nodes = $ServerName;
    }


foreach ($Node in $Nodes)
{
    Install-RemoteCertificate -TargetNodeName $Node -Certfile $CertFile -PFXFile $PFXFile -PFXPassword $PFXPassword -DomainBuildCred $Credential;

    Install-SQLCertificate -TargetNodeName $Node -InstanceName $InstanceName -Thumbprint $Thumbprint -Credential $Credential;

}

Restart-SQLActiveNode -Parameters.....

