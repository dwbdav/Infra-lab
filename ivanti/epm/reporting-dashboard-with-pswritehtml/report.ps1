############################################### SQL ################################################################
$Exporthtml = "C:\temp\default.htm"
$ServerSQL = "epm2024.monlab.lan"
$database = "EPM"
$user = "sa"

# Best solution with password encrypt
#$password = ConvertTo-SecureString -String "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
#$creds    = New-Object -TypeName System.Management.Automation.PsCredential -ArgumentList ($user, $password)

# bad solution with visible password
$password = "Password1"
$creds = New-Object -TypeName System.Management.Automation.PsCredential -ArgumentList ($user, (ConvertTo-SecureString -String $password -AsPlainText -Force))
$PassSQL = $creds.GetNetworkCredential().Password
############################################### SQL ################################################################

$ApplicationFilter1 = "Visual C++ 2022 X86"
$ApplicationFilter2 = "Edge"
$VariableFilter1    = "JAVA_HOME"

Import-Module -Name PSwriteHTML
. ([scriptblock]::Create((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DavidWuibaille/Repository/main/Function/DashboardEPM.ps1" -UseBasicParsing).Content))



# Generating HTML report
New-HTML -TitleText 'Dashboard' {

    # Start Applications Tab
    New-HTMLTab -Name 'Application' {
        New-HTMLPanel {
            New-HTMLSection  -HeaderText $ApplicationFilter1 {
                New-HTMLTable -DataTable $Application1 -HideFooter -SearchPane
            }           
        }
        New-HTMLPanel {
            New-HTMLSection  -HeaderText $ApplicationFilter2 {
                New-HTMLTable -DataTable $Application2 -HideFooter -SearchPane
            }           
        }
        New-HTMLPanel {
            New-HTMLSection  -HeaderText $VariableFilter1 {
                New-HTMLTable -DataTable $Variable1 -HideFooter -SearchPane
            }           
        }
    }

	
    # Start Windows Tab
    New-HTMLTab -Name 'Windows' {		
        New-HTMLSection -HeaderText 'Windows Version' {
            New-HTMLPanel {
                # Chart for full version details
                New-HTMLChart -Title "Version" {
                    New-ChartToolbar -Download
                    New-ChartEvent -DataTableID 'WindowsOS' -ColumnID 1
                    foreach ($groupe in $WindowsgroupesVersion) {
                        New-ChartDonut -Name $($groupe.Name) -Value $($groupe.Count)
                    }
                }
            }
        }

        # Hidden section to display Windows data table
        New-HTMLSection -Invisible {			
            New-HTMLPanel {
                New-HTMLTable -DataTable $WindowsDetails -DataTableID 'WindowsOS' -HideFooter
            }
        }        
    }


    # Start Bitlocker Tab
    New-HTMLTab -Name 'Bitlocker' {	
        New-HTMLSection -HeaderText 'Bitlocker Status' {
            New-HTMLPanel {
                # Chart for full version details
                New-HTMLChart -Title "Version" {
                    New-ChartToolbar -Download
                    New-ChartEvent -DataTableID 'BitlockerStatus' -ColumnID 1
                    foreach ($groupe in $BitlockerStatus       ) {
                        New-ChartDonut -Name $($groupe.Name) -Value $($groupe.Count)
                    }
                }
            }
        }
		
        # Section for Bitlocker details
        New-HTMLSection -HeaderText 'Bitlocker detail' {
            New-HTMLTable -DataTable $BitlockerDetails -DataTableID 'BitlockerStatus' -HideFooter {
                "<H1>Bitlocker Details</H1>"
            }
        }
    }


	# Start Hardware Tab
    New-HTMLTab -Name 'Model' {	
        New-HTMLSection -HeaderText 'Hardware' {
            New-HTMLPanel {
                # Chart for full version details
                New-HTMLChart -Title "Version" {
                    New-ChartToolbar -Download
                    New-ChartEvent -DataTableID 'Modelcount' -ColumnID 1
                    foreach ($groupe in $Modelscount                  ) {
                        New-ChartDonut -Name $($groupe.Name) -Value $($groupe.Count)
                    }
                }
            }
        }
		
        # Section for Models details
        New-HTMLSection -HeaderText 'Models details' {
            New-HTMLTable -DataTable $WorkstationModels -DataTableID 'Modelcount' -HideFooter {
                "<H1>Models Details</H1>"
            }
        }
    }

    # Footer with the report date
    New-HTMLFooter {
        New-HTMLText -Text "Date of this report (GMT time): $(Get-Date)" -Color Blue -Alignment Center 
    }
} -FilePath $Exporthtml -Online


