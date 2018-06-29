###############################################################################################################
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

Function Load-PSModule
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

Function CheckClusterWMI
{
    param ( [Array]$Nodes )

    Write-Host "Getting the cluster nodes…" -ForegroundColor Green -NoNewline;
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
                    # Success 
                    $result = (get-wmiobject -class "MSCluster_CLUSTER" -namespace "root\MSCluster" -authentication PacketPrivacy -computername $Node -erroraction stop).__SERVER 
                    Write-host -ForegroundColor Green      " : WMI query succeeded " 
                } 
            Catch 
                { 
                    # Failure
                    Write-host -ForegroundColor Red -NoNewline  " : WMI Query failed " 
                    Write-host  "//"$_.Exception.Message 
                } 
            } 
   
       }
}