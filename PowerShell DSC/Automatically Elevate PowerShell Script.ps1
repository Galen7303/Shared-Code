$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

if ($myWindowsPrincipal.IsInRole($adminRole))
    {
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + “(Elevated)”
        clear-host
    }
 else
    {
        $newProcess = new-object System.Diagnostics.ProcessStartInfo “PowerShell”;
        $newProcess.Arguments = $myInvocation.MyCommand.Definition;
        $newProcess.Verb = “runas”;
        [System.Diagnostics.Process]::Start($newProcess);
        exit
    }
# Add the code of your script here
$CertShare = '\\GIG01SRVDSCMAN1\C$\PublicKeys\';
$CertFile = 'DSCPublicKey.cer';
$PFXFile = 'DSCPrivateKey.pfx';
$PFXPassword = 'M$$QL$3RV3R';

$CertLocation = Join-Path -Path $CertShare -ChildPath $CertFile;
$PFXLocation = Join-Path -Path $CertShare -ChildPath $PFXFile;
$Target = [System.Net.Dns]::GetHostName();
	
Import-Certificate -CertStoreLocation Cert:\LocalMachine\My -FilePath $CertLocation;

Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -FilePath $PFXLocation -Password (ConvertTo-SecureString -String $PFXPassword -AsPlainText -Force);
