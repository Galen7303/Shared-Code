<#

.SYNOPSIS
The script serves as the top shell for processing Infrastructure builds using PowerShell DSC

.DESCRIPTION
The script serves as the top shell for processing Infrastructure builds using PowerShell DSC. The DSCType Variable
directs the processing to the appropriate DSC Configuration Block.

.PARAMETER Param1

.PARAMETER Param2

.PARAMETER Param3

.EXAMPLE
 Invocation:                                                                                                 


.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Initial Write of Script as a proof of concept in Powershell 				              
  
.LINK
 none

#>

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

###############################################################################################################
#                                                                                                             #
# Main Code Execution Starts Here                                                                             #
#                                                                                                             #
###############################################################################################################

Set-StrictMode -Version 1.0
#Requires -RunAsAdministrator
#Requires -Version 5.0

Load-PSModule activedirectory;

Clear;
$Version = "1.0";

$SQLServer = "MININT-435D8DN\SQL2016INST1";
[System.Collections.ArrayList]$Accounts = @();


$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $SQLServer; Database = Master; Integrated Security = True;"

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "EXEC sp_helpsrvrolemember 'sysadmin';";
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
[void]$SqlAdapter.Fill($DataSet)


# Output each Account
ForEach ($row in $DataSet.Tables[0])
    {
       $Account = $row["MemberName"] | Where-object { ( $_ -inotmatch "sa" ) -and ( $_ -inotmatch "NT Service" ) };
       if ( $Account -ne $null )
        {
            [void]$Accounts.Add( $Account );
        }
    }
 
[void]$sqlConn.Close;

ForEach ( $Account in $Accounts )
    {
        Write-Host $Account -ForegroundColor Green;
        ( $Domain, $UserName ) = $Account.split('\');
        $ADAccount = Get-ADUser -Filter { SAMAccountName -eq $UserName } -Server $Domain;
        $ADGroups = Get-ADUser -Filter { SAMAccountName -eq $UserName } -Server $Domain -Properties MemberOf;
        Get-ADGroup -Identity 
        $ADAccount;
        $ADGroups.MemberOf;
    }

