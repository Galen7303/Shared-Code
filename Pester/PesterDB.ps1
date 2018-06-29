clear;

[System.Collections.ArrayList]$Expected = @();

[string]$NodeName = "MININT-435D8DN";
[string]$InstanceName = "SQL2016INST1";
[string]$Database = "Test";
[string]$Type = "Service" # "Server" | "Service"
[string]$Parameters = "WRRS";


###############################################################################################################
#                                                                                                             #
#  Load in the Various Functions, Modules and Configurations we will need                                     #
#                                                                                                             #
###############################################################################################################

# Load the DSC Helper Functions
$PesterHelperFunctionsFile = Join-Path -Path $PSScriptRoot -ChildPath "PesterDB_Helper-Functions.ps1";
. $PesterHelperFunctionsFile;
Write-Host "Pester Helper Functions Loaded." -ForegroundColor Green;


# Load the Required Modules
Load-PSModule -ModuleName SQLPS;



# Execute the Stored Procedure to return the
# Expected Values for the Server in Question
( $Expected ) = ConnectSQLExecProc `
                    -NodeName $NodeName `
                    -InstanceName $InstanceName `
                    -Database $Database `
                    -Type $Type `
                    -Parameters $Parameters;

# The ArrayList gets unrolled from ConnectSQLExecProc
# function return - dropping $Expected[0] fixes this.                 
$Expected = $Expected[1];


$Servers = $Expected.ServerName | select -uniq;

foreach ( $Server in $Servers )
    { 
        for ( $i=0; $i -lt $Expected.Count; $i++ )
            {
                If ( $Expected[$i].ServerName -eq $Server )
                    {
                        PerformCheck `
                            -ServerName $Expected[$i].ServerName `
                            -Key $Expected[$i].Key `
                            -ExpectedValue $Expected[$i].Value `
                            -Tags $Expected[$i].Tags `
                            -MatchType $Expected[$i].MatchType;
                    }
            }
    }
