#param(
#    [parameter(Mandatory = $true)]
#    [string[]]$ComputerName
#	)

Set-StrictMode -Version 1.0;

#requires -version 4.0 
#requires –runasadministrator

Clear;

[string]$Version                 = "1.0";
[string]$ComputerName            = "MININT-435D8DN";
[string]$HelperFile              = "EstateChecks_HelperFunctions.ps1";
[array]$Nodes                    = @();


#$ComputerName = "NSSSWFC007.sle.s.mil.uk";


# Load the Required PS Modules
Load-PSModule FailoverClusters;


# Check the Helper File exists
$HelperFunctionsFile = Join-Path -Path $PSScriptRoot -ChildPath $HelperFile;
if ( Test-Path $HelperFunctionsFile )
    {
        # Load the DSC Helper Functions
        . $HelperFunctionsFile;
        Write-Host "Helper Functions Loaded." -ForegroundColor Green;
    }
else
    {
        Write-Host "$HelperFunctionsFile Not Found..." -ForegroundColor Red;
        exit 1;
    }


# Check if the Target Node is a Clustered Node or Standalone
Try 
    { 
        $result = (get-wmiobject -class "MSCluster_CLUSTER" -namespace "root\MSCluster" -authentication PacketPrivacy -computername $ComputerName -erroraction stop).__SERVER
        
        # Clustered 
        Write-Host "$ComputerName is clustered" -ForegroundColor Green;
        $Nodes = (Get-ClusterNode -Cluster $ComputerName).name;
        CheckClusterWMI -Nodes $Nodes;
    } 
Catch 
    { 
        # Stand-Alone
        Write-Host "$ComputerName is not clustered" -ForegroundColor Yellow;
        $Nodes = $ComputerName;
    }


# Ping the Target to see if it is up
$Result = Test-NetConnection -ComputerName $Computer;
If ( $Result.PingSucceeded -eq $true )
    {
        Write-Host "$Computer responded to Ping...." -ForegroundColor Green;
    }
else
    {
        Write-Host "$Computer did NOT respond to Ping..." -ForegroundColor Red;
    }


# Enumerate the SQL Server Services on the Target.
foreach ( $Node in $Nodes )
    {
        Write-Host "`n`n`n";
        Write-Host "********************************************************************************************" -ForegroundColor Green;
        Write-Host "$Node has Services: " -ForegroundColor Green;
        $SQLServices = Get-Service -ComputerName $Computer -ErrorAction SilentlyContinue | Where { $_.DisplayName -match "SQL Server \(" };
        $SQLAgents = Get-Service -ComputerName $Computer -ErrorAction SilentlyContinue | Where { $_.DisplayName -match "SQL Server Agent \(" };
        $SQLServices | Format-Table DisplayName, Name, Status;
        $SQLAgents | Format-Table DisplayName, Name, Status;
    }

