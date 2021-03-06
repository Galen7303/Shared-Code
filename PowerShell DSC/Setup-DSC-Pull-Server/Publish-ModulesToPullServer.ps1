function Publish-ModuleToPullServer 
 { 
     [CmdletBinding()] 
     [Alias("pmp")] 
     [OutputType([void])] 
     Param 
     ( 
         # Name of the module. 
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)] $Name, 
                  
         # This is the location of the base of the module. 
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)] $ModuleBase, 
          
         # This is the version of the module 
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=2)] $Version, 
 
 
         $PullServerWebConfig = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer\web.config", 
 
 
         $OutputFolderPath = $null 
     ) 
 
 
    Begin
    {
        if (-not($OutputFolderPath))
        {
            if ( -not(Test-Path $PullServerWebConfig))
            {
                $OutputFolderPath = "C:\Program Files\WindowsPowerShell\DSCService\Modules";
            }
            else
            {
                # If the Pull Server exists, figure out the module path of the pullserver 
                # and use this value as output folder path.
                $webConfigXml = [xml](cat $PullServerWebConfig)
                $moduleXElement = $webConfigXml.SelectNodes("//appSettings/add[@key = 'ModulePath']")
                $OutputFolderPath =  $moduleXElement.Value
            }
        }
    }
     Process 
         { 

            Write-Verbose "Name: $Name , ModuleBase : $ModuleBase ,Version: $Version" 
            $targetPath = Join-Path $OutputFolderPath "$($Name)_$($Version).zip" 
 
            $OutputDir = $env:TEMP;

            if ( Test-Path $OutputDir\$Version )
                {
                    Remove-Item  "$OutputDir\$Version" -Recurse -Force; 
                }

            if ( Test-Path "$($ModuleBase)\$Name\$Version" )
                {

                    Copy-Item "$($ModuleBase)\$Name\$Version" $OutputDir -Recurse;
                    Rename-Item "$OutputDir\$Version" "$OutputDir\$Name";

                    if (Test-Path $targetPath) 
                       { 
                             Compress-Archive -DestinationPath $targetPath -Path "$OutputDir\$Name" -Update;
                       } 
                    else 
                       { 
                             Compress-Archive -DestinationPath $targetPath -Path "$OutputDir\$Name";
                       }

                    Remove-Item  "$OutputDir\$Name" -Recurse -Force;
                }

         } 
     End 
         { 
            # Now that all the modules are published generate thier checksum. 
            New-DscChecksum -Path $OutputFolderPath 
        
         } 
 }  

#################################################################################################
##
## Main Code Execution
##
#################################################################################################

clear;

$DSCResources = Get-DscResource	 | Where { $_.ModuleName -ne "PSDesiredStateConfiguration" -and $_.ImplementedAs -eq "PowerShell" } | select-object ModuleName, Version -Unique 
Foreach ( $DSCResource in $DSCResources )
	{
	Publish-ModuleToPullServer -Name $DSCResource.ModuleName -ModuleBase "C:\Program Files\WindowsPowerShell\Modules" -Version $DSCResource.Version	
	}	

