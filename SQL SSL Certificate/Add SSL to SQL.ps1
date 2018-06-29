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

function Get-TargetInstance
{
     param ( )

	Try
		{

        [Array]$SQLInstances = @();		

		$RegEntries = Get-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
		ForEach ( $RegEntry in $RegEntries ) 
			{
                $SQLInstance = $RegEntry.psobject.properties | Where-Object {$_.name -NotMatch "PS*"} | % {$_.name};
                if ( $SQLInstance -ne $null )
                    {
                        $SQLInstances += $SQLInstance;
                    }
			}
						
		if ( $SQLInstances.Count -eq 0 )
			{
				Write-Host "No Local SQL Server Instances were Found...";
				Exit 1;
			}
        return ( ,$SQLInstances );
        }
    Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

Function Get-InstalledCertificates
{
     param ( )

	Try
		{
            [Array]$Certificates = @();

            $Certs = Get-Childitem Cert:\localmachine\my
            ForEach ( $Cert in $Certs )
                {
                    $Certificates += $Cert.Thumbprint;
                }
            return ( ,$Certificates );
        }
    Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

Function Set-SSLCertificate
{
    param ( [string]$InstanceName, [String]$Thumbprint )

    Try
        {
            $registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceName\MSSQLServer\SuperSocketNetLib\";
            Set-ItemProperty -path $registryPath -name Certificate -value $Thumbprint;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

Function Set-RestartService
{
    param ( [string]$InstanceName )

    Try
        {
            Restart-Service -displayname "SQL Server ($InstanceName)" -Force | out-null;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

Function Get-InstanceCertificateChoice
{
    param ( [Array]$Instances, [Array]$Thumbprints )

    Try
        {
            Add-Type -AssemblyName System.Windows.Forms | Out-Null
            Add-Type -AssemblyName System.Drawing | Out-Null;

		    # Now build a form to display the target instances and 
		    # allow the user to pick the instance from it
		    $Form = New-Object System.Windows.Forms.Form;
		    $Form.width = 350;
		    $Form.height = 330;
		    $Form.Text = "Select Instance:";
		    $Form.StartPosition = "CenterScreen";
            $Form.MinimizeBox = $false;
            $Form.MaximizeBox = $false;
            $Form.KeyPreview = $true
            $Form.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
                {$Form.DialogResult = "OK";$Form.Close()}})
            $Form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
                {$Form.DialogResult = "Cancel";$Form.Close()}})


            # Build the Instance Drop down box
   		    $InstanceDropDownLabel = New-Object System.Windows.Forms.Label;
		    $InstanceDropDownLabel.Location = New-Object System.Drawing.Size(10,10);
		    $InstanceDropDownLabel.Size = New-Object System.Drawing.Size(150,30);
		    $InstanceDropDownLabel.Text = "Instance(s) Found:";
		    $Form.Controls.Add($InstanceDropDownLabel);

		    $InstanceDropDown = New-Object System.Windows.Forms.ComboBox;
		    $InstanceDropDown.Location = New-Object System.Drawing.Size(90,50);
		    $InstanceDropDown.Size = New-Object System.Drawing.Size(150,180);


            # Build the Certificate Drop down box
		    $CertificateDropDownLabel = New-Object System.Windows.Forms.Label;
		    $CertificateDropDownLabel.Location = New-Object System.Drawing.Size(10,110);
		    $CertificateDropDownLabel.Size = New-Object System.Drawing.Size(150,30);
		    $CertificateDropDownLabel.Text = "Certificate(s) Found:";
		    $Form.Controls.Add($CertificateDropDownLabel);

		    $CertificateDropDown = New-Object System.Windows.Forms.ComboBox;
		    $CertificateDropDown.Location = New-Object System.Drawing.Size(90,150);
		    $CertificateDropDown.Size = New-Object System.Drawing.Size(1500,80);



		    $OKButton = new-object System.Windows.Forms.Button;
		    $OKButton.Location = new-object System.Drawing.Size(70,200);
		    $OKButton.Size = new-object System.Drawing.Size(100,35);
		    $OKButton.Text = "OK";

		    $CancelButton = New-Object System.Windows.Forms.Button;
		    $CancelButton.Location = New-Object System.Drawing.Size(190,200);
		    $CancelButton.Size = New-Object System.Drawing.Size(100,35);
		    $CancelButton.Text = "Cancel";


		    ForEach ($Instance in $Instances) 
			    {
		    	    $InstanceDropDown.Items.Add($Instance) | Out-Null;
			    }
		
		    #Set the Default Entry to be the first instance in the list
		    $InstanceDropDown.SelectedItem = $Instances[0];
		    $Form.Controls.Add($InstanceDropDown);


		    ForEach ($Thumbprint in $Thumbprints) 
			    {
		    	    $CertificateDropDown.Items.Add($Thumbprint) | Out-Null;
			    }
		
		    #Set the Default Entry to be the first instance in the list
		    $CertificateDropDown.SelectedItem = $Thumbprints[0];
		    $Form.Controls.Add($CertificateDropDown);


		    $OKButton.Add_Click(
			    {
				    $Form.DialogResult = "OK";
				    $Form.close();
			    }
		    )
		    $Form.Controls.Add($OKButton);


		    $CancelButton.Add_Click(
			    {
				    $Form.DialogResult = "Cancel";
				    $Form.close();
			    }
		    )
		    $Form.Controls.Add($CancelButton);


		    $Form.Add_Shown({$Form.Activate()});


		    $result = $Form.ShowDialog();
		
		    # if the "OK" button was pressed
		    if($result -eq "OK")
		        {
				    $InstanceChoice = $InstanceDropDown.SelectedItem.ToString();
                    $CertificateChoice = $CertificateDropDown.SelectedItem.ToString();
                    
				    return ( $InstanceChoice, $CertificateChoice );
			    }
	        else
		        {
				    # cancel was pressed, so Exit
                    Write-Host "Cancel Pressed - Exiting." -ForegroundColor Red;
		    	    Exit 1;
		        }

        }
	Catch
		{
			Write-Host $_.Exception.ToString();
			Exit 1;
		}
}

Set-StrictMode -Version 1.0;
#requires -version 4.0 
#requires –runasadministrator


$Instances = Get-TargetInstance;
$Thumbprints = Get-InstalledCertificates;

( $InstanceChoice, $ThumbprintChoice ) = Get-InstanceCertificateChoice -Instances $Instances -Thumbprints $Thumbprints;

Set-SSLCertificate -InstanceName $InstanceChoice -Thumbprint $ThumbprintChoice;

Set-RestartService -InstanceName $InstanceChoice;