Import-Module FailoverClusters

Clear;

# Specify the Cluster to Connect to
#$Cluster = Read-Host "Enter the Cluster to Adjust...";
$Cluster = "GIG00CLSSQLT00B";

# Find all of the nodes within this Cluster
$ClusterNodes = Get-ClusterNode -Cluster $Cluster;

# Show the NodeName, State and NodeWeight of all nodes
Write-Host "Current Node Weights are:" -Foreground Red;
$ClusterNodes | ft -Property NodeName, State, NodeWeight;


# Loop through the Cluster Nodes to Adjust the Weight...
ForEach ($Node in $ClusterNodes)
    {
        $CurrentNodeWeight = (Get-ClusterNode $Node.Name).NodeWeight;
        Write-Host "Current Weight for Node: $Node is $CurrentNodeWeight";

        Do { $NewNodeWeight = Read-Host "Enter the New Weight (0 or 1) for Node: $Node" } While ((0..1) -notcontains $NewNodeWeight)

        # Make the Adjustment
        (Get-ClusterNode $Node.Name).NodeWeight = $NewNodeWeight;

    }

# Find all of the nodes within this Cluster
$ClusterNodes = Get-ClusterNode -Cluster $Cluster;

# Show the NodeName, State and NodeWeight of all nodes
$ClusterNodes | ft -Property NodeName, State, NodeWeight;
