Import-Module FailoverClusters

Function ConvertCIDRToClassless
{

    [string]$ClusterCIDR;

    [int64]$Int64 = [convert]::ToInt64(('1' * $ClusterCIDR + '0' * (32 - $ClusterCIDR)), 2);

    return '{0}.{1}.{2}.{3}' -f ([math]::Truncate($Int64 / 16777216)).ToString(), `
                                ([math]::Truncate(($Int64 % 16777216) / 65536)).ToString(), `
                                ([math]::Truncate(($Int64 % 65536)/256)).ToString(), `
                                ([math]::Truncate($Int64 % 256)).ToString();

}


# Import the PowerShell Data File
$ConfigurationDataFile = "\\GIG01SRVDSCMAN1\d$\DSC Scripts\Build Scripts\ConfigurationData\App1_SQL2016INST1_4NodeAG.psd1";
$ConfigurationData = Import-PowerShellDataFile -Path $ConfigurationDataFile;

# Get the Cluster IP Addresses from the Data File
$ClusterName        = $ConfigurationData.AllNodes.Cluster_Name;
$Cluster_IPAddress1 = $ConfigurationData.AllNodes.Cluster_IPAddress1;
$Cluster_IPAddress2 = $ConfigurationData.AllNodes.Cluster_IPAddress2;

$split              = $Cluster_IPAddress1.split('/');
$ClusterIP1         = $split[0];
$ClusterCIDR        = $split[1];
$ClusterSubnet1     = ConvertCIDRToClassless -ClusterCIDR $ClusterCIDR;


$split              = $Cluster_IPAddress2.split('/');
$ClusterIP2         = $split[0];
$ClusterCIDR        = $split[1];
$ClusterSubnet2     = ConvertCIDRToClassless -ClusterCIDR $ClusterCIDR;


# We need to determine which IP Address is present, and add the second one
$ClusterIPAddress = Get-ClusterResource -Cluster $ClusterName -Name "Cluster IP Address" | Get-ClusterParameter -Name Address
$ClusterIPSubnetMask = Get-ClusterResource -Cluster $ClusterName -Name "Cluster IP Address" | Get-ClusterParameter -Name SubnetMask


Add-ClusterResource -Cluster $ClusterName -Group "Cluster Group" -Name "Cluster IP Address 2" -ResourceType "IP Address";
$IPResource = Get-ClusterResource -cluster $ClusterName "Cluster IP Address 2"


If ( $Cluster_IPAddress1 -Match $ClusterIPAddress.Value )
    {

    $param1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPResource,Address,$ClusterIP2;
    $param2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPResource,SubnetMask,$ClusterSubnet2[1];

    }

If ( $Cluster_IPAddress2 -Match $ClusterIPAddress.Value )
    {

    $param1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPResource,Address,$ClusterIP1;
    $param2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $IPResource,SubnetMask,$ClusterSubnet1[1];

    }

$AllParams = $param1,$param2;
$AllParams | Set-ClusterParameter -Cluster $ClusterName;

Set-ClusterResourceDependency -Cluster $ClusterName -Resource "Cluster Name" -Dependency "[Cluster IP Address] or [Cluster IP Address 2]";
