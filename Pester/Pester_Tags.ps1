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

function Wrapper
{
    param ( [string]$Key, [System.Collection.ArrayList]$TestCases, [System.Collection.ArrayList]$Tags )

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



$Key = "CPU";
$Expected = 8;
$Observed = 8;
$testCases = @( @{ Expected = $Expected; Observed = $Observed } );
$Tags = @('OAT', 'Hardware', 'Daily');

Describe -Tag $Tags "Expected and Observed Values for $Key" {
it "should return <Expected>" -TestCases $testcases {
    param ( $Expected, $Observed )
        $Observed | Should Be $Expected;
    }
}


$Key = "Memory";
$Expected = 32;
$Observed = 32;
$testCases = @( @{ Expected = $Expected; Observed = $Observed } );
$Tags = @('OAT', 'Hardware');


Describe -Tag $Tags "Expected and Observed Values for $Key" {
it "should return <Expected>" -TestCases $testcases {
    param ( $Expected, $Observed )
        $Observed | Should Be $Expected;
    }
}






Import-Module –Name Pester -MinimumVersion "4.3.1";

# Variables for Function
$Key = "CPU";
$Expected = 8;
$Observed = 8;
$testCases = @( @{ Expected = $Expected; Observed = $Observed } );
$Tags = @('OAT', 'Hardware', 'Daily');


# Run this from the command line, not from inside the script.
#Invoke-Pester D:\Microsoft\Development\Pester\Pester_Tags.ps1 -Tag 'Hardware'