# Install Certificate and PFX file
# Make sure this is Run Administrator

clear;
$CertShare = '\\GIG01SRVDSCMAN1\C$\PublicKeys\';
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