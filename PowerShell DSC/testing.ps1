function Copy-DSCResources
{
    param ( [string]$SourceDirectory, [string]$TargetDestination)
    
    $SourceDirectory = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\"
    $TargetDirectory = "C:\Temp"

    Try
        {
            $Folders = Get-ChildItem $SourceDirectory;
            foreach ( $Folder in $Folders )
                {
                    Write-Host $Folder;
                    $Source = $SourceDirectory + '\' + $Folder;
                    Copy-Item $Source -Destination $TargetDirectory -Recurse
                }
            
        }
       Catch
             {
                    Write-Host $_.Exception.ToString();
                    Exit 1;
             }
}




Copy-DSCResources 
