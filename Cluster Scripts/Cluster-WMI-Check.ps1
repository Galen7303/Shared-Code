Set-ExecutionPolicy unrestricted

clear;

If(import-module failoverclusters) 
    {

    Write-Host "Imported Cluster module"

    }

Write-Host "Getting the cluster nodes…" -NoNewline 
$nodes = (Get-ClusterNode -Cluster NSSSWFC007.sle.s.mil.uk).name;
Write-host "Found the below nodes " 
Write-host " " 
$nodes 
Write-host "" 
Write-host "Running the WMI query…." 
Write-host " " 

ForEach ($Node in $nodes) 
    { 
        
    Write-Host -NoNewline $node 

    if($Node.State -eq "Down") 
            {
            Write-Host -ForegroundColor White    " : Node down skipping" 
            } 
    
    else 
        {

        Try 
            { 
                #success 
                $result = (get-wmiobject -class "MSCluster_CLUSTER" -namespace "root\MSCluster" -authentication PacketPrivacy -computername $Node -erroraction stop).__SERVER 
                Write-host -ForegroundColor Green      " : WMI query succeeded " 
            } 
        Catch 
            { 
                #Failure
                Write-host -ForegroundColor Red -NoNewline  " : WMI Query failed " 
                Write-host  "//"$_.Exception.Message 
            } 
        } 
   
   }
