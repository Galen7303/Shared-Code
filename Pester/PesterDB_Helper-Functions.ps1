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

function ConnectSQLExecProc
{
    param(  [Parameter(Position=0,mandatory=$true)] [string]$NodeName,
            [Parameter(Position=1,mandatory=$true)] [string]$InstanceName,
            [Parameter(Position=2,mandatory=$true)] [string]$Database,
            [Parameter(Position=3,mandatory=$true)] [ValidateSet('Server','Service')][string]$Type,
            [Parameter(Position=4,mandatory=$true)] [string]$Parameters )

    Try
        {
            [System.Collections.ArrayList]$Expected = @()

            Switch ( $InstanceName )
                {
                    'MSSQLSERVER'
                        {
                            $SQLServer =  $NodeName;
                        }
                    ''
                        {
                            $SQLServer =  $NodeName;
                        }
                    default
                        {
                            $SQLServer = $NodeName + '\' + $InstanceName;
                        }
                }

            Switch ($Type) 
                {
                    'Server'  #ServerName
                        {
                            $SqlQuery = 'EXEC GetServerExpectedValues @Server = ' + ' ''' + $Parameters + '''';
                        }
                    'Service' #Service Name
                        {
                            $SqlQuery = 'EXEC GetServerExpectedValues @Service = ' + ' ''' + $Parameters + '''';
                        }
                }
 
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = “Server=$SQLServer;Database=$Database;Integrated Security=True”;
            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand;
            $SqlCmd.CommandText = $SqlQuery;
            $SqlCmd.Connection = $SqlConnection;
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter;   
            $SqlAdapter.SelectCommand = $SqlCmd;
            $DataSet = New-Object System.Data.DataSet;
            $SqlAdapter.Fill($DataSet);
            $SqlConnection.Close();
            
            foreach ( $row in $DataSet.Tables[0].Rows )
                {
                    [string]$Object = $null;
                    foreach ( $Column in $DataSet.Tables[0].Columns )
                        {
                            $Object += $row[$column].ToString() + "|";
                        }
                    ( $ServerName, $Key, $ExpectedValue, $Tags, $MatchType, $Junk ) = $Object.split("|");
                    $ArrayItem = $null;
                    $ArrayItem = New-Object PsObject -Property @{ ServerName = $ServerName; Key = $Key; Value = $ExpectedValue; Tags = $Tags; MatchType = $MatchType };
                    [void]$Expected.Add( $ArrayItem );
                }
            
            return ,$Expected;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Perform-PesterTest
{
    param ( [Parameter(Position=0,mandatory=$true)] [string]$Key, 
            [Parameter(Position=1,mandatory=$true)] [Array]$testCases,
            [Parameter(Position=2,mandatory=$true)] [Array]$Tags )

    Try
        {
            
            Describe -Tag $Tags "Expected and Observed Values for $Key" {
                        it "should return <Expected>" -TestCases $testcases {
                            param ( $Expected, $Observed )
                                $Observed | Should Be $Expected;
                            }
                        }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Perform-PesterRangeTest
{
    param ( [Parameter(Position=0,mandatory=$true)] [string]$Key, 
            [Parameter(Position=1,mandatory=$true)] [Array]$testCases, 
            [Parameter(Position=2,mandatory=$true)] [Array]$Tags )

    Try
        {
            ( $LowerBound, $UpperBound ) = $ExpectedValue.Split(':');
            Describe "Expected and Observed Values for $Key" {
                it "should return $ExpectedValue" {
                        $ObservedValue | Should BeGreaterThan $LowerBound
                        $ObservedValue | Should BeLessThan $UpperBound
                    }
                }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function PerformCheck
{
    param ( [Parameter(Position=0,mandatory=$true)] [string]$ServerName, 
            [Parameter(Position=1,mandatory=$true)] [string]$Key, 
            [Parameter(Position=2,mandatory=$true)] [string]$ExpectedValue, 
            [Parameter(Position=3,mandatory=$true)] [string]$Tags, 
            [Parameter(Position=4,mandatory=$true)] [string]$MatchType )

    Try
        {
            #Write-Host $ServerName -ForegroundColor Green -NoNewline;
            #Write-Host $Key -ForegroundColor Green -NoNewline;
            #Write-Host $ExpectedValue -ForegroundColor Green -NoNewline;
            #Write-Host $Tags -ForegroundColor Green -NoNewline;
            #Write-Host $MatchType -ForegroundColor Green;


            # Make sure the Server to be collected is actually up and running
            $PingStatus = Test-NetConnection -ComputerName $ServerName;
            if ( $PingStatus.Status -eq $false )
                {
                    Write-Host "Host: " $ServerName "is DOWN...." -ForegroundColor Red;
                    return;
                }

            # Need a process which collects the Observed Values from the servers
            # within the estate so we can compare against the $ExpectedValue
            $ObservedValue = Get-ObservedValue -ServerName $ServerName -Key $Key;

            $testCases = @( @{ Expected = $ExpectedValue; Observed = $ObservedValue } );

            $ExecutionTags = @();
            $ExecutionTags = $Tags.split(',').TrimStart();

            Switch ( $MatchType )
                {
                    "Exact" 
                        {
                            Perform-PesterTest -Key $Key -TestCases $testCases -Tags $ExecutionTags;
                        }
                    "Range" 
                        {
                            Perform-PesterRangeTest -Key $Key -TestCases $testCases -Tags $ExecutionTags;
                        }
                    default
                        {
                            Write-Host "Unknown MatchType... Should be either 'Exact' or 'Range'." -ForegroundColor Red;
                            Exit 0;
                        }
                }
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

function Get-ObservedValue
{
    param ( [Parameter(Position=0,mandatory=$true)] [string]$ServerName, 
            [Parameter(Position=1,mandatory=$true)] [string]$Key )

    Try
        {
            Switch ( $Key )
                {
                    'CPU'
                        {
                            $ObservedValue = (Get-WMIObject -ComputerName $ServerName -Class Win32_Processor).NumberOfCores
                        }
                    'Memory'
                        {
                            $ObservedValue = 
                        }
                    'Disk'
                        {
                        }
                    'NICs'
                        {
                        }
                    default
                        {
                            Write-Host "Unknown Key $Key to search for..." -ForegroundColor Red;
                        }
                }
            return $ObservedValue;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}