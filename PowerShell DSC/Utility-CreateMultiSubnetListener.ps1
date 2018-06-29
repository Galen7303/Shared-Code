$NodeName = 'GIG01SRVSQLT001';
$InstanceName = 'SQL2016INST1';
$AvailabilityGroup = 'Test_AG';
$IpAddress = "10.57.204.236/255.255.255.0","10.57.109.236/255.255.255.0";


$sqlServerObject = Connect-SQL -SQLServer $NodeName -SQLInstanceName $InstanceName

$availabilityGroupObject = $sqlServerObject.AvailabilityGroups[$AvailabilityGroup]
if ($availabilityGroupObject)
{
    $newListenerParams = @{
        Name = $Name
        InputObject = $availabilityGroupObject
    }
}

if ($IpAddress.Count -gt 0)
{
    New-VerboseMessage -Message "Listener set to static IP-address(es); $($IpAddress -join ', ')"
    $newListenerParams += @{
        StaticIp = $IpAddress
    }
}

$newListenerParams

New-SqlAvailabilityGroupListener @newListenerParams -ErrorAction Stop | Out-Null
