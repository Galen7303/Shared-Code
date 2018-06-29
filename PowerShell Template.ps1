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

Clear;
$Version = "1.0";
