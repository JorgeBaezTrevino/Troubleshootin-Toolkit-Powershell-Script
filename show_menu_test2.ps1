#Main menu GUI
function mainMenu
 {
            param (
            [string]$Title = ‘Main Options’
            )
            
            Write-Host “================ $Title ================”
    
            Write-Host “1: Press ‘1’ for Ping."
            Write-Host “2: Press ‘2’ for Trace-Route.”
            Write-Host “3: Press ‘3’ for DNS Lookup test. (SKIP FOR NOW)”
            Write-Host "4: Press '4' for Port Connection Configurations"
            Write-Host “Q: Press ‘Q’ to quit.”
 }


#Port connection menu GUI
function portMenu
{
            param (
            [string]$Title = "Port Connection settings" 
            )

            Write-Host “============ $Title ============”

            Write-Host "1: Testing Port Connectivity."
            Write-Host "2: Finding Listening Ports"
            Write-Host "Q: Press 'Q' to quit."
}
 
do
 {
            #main menu options code 
            mainMenu
            $input = Read-Host “Please make a selection”
            switch ($input)
            {
            ‘1’ {
                
                 $ping = Read-Host -Prompt "Enter Hostname"
                 ping $ping
            } 
            ‘2’ {
                 $tracert_hostname = Read-Host -Prompt "Enter Hostname"
                 tracert $tracert_hostname
            }
             ‘3’ {
                 
                 ‘You chose option #3’
            } 
             ‘4’ {
                 #Port connection menu for other configurations code
                 do {
                        portMenu
                        $input = Read-Host "Enter Selection"
                        switch ($input)
                        {
                            '1' {
                               $Tst_ntconnect_port = Read-Host -Prompt "enter port # or enter 'none' for testing ping connectivity)"
                               $InfoLvl = Read-Host -Prompt "Enter detail amount (0 - none, 1 detailed)"
                               $route_cnstrt = Read-Host -Prompt "Enter Domain name (enter 0 for default)"

                               #Test ping connectivity
                               if ($Tst_ntconnect_port -eq 'none' -and $InfoLvl -eq  0 -and $route_cnstrt -eq 0) {
                                    Test-NetConnection
                               }
                               #Test ping connectivity with detailed results
                               elif ($Tst_ntconnect_port -ne "none" -and $InfoLvl -eq 0) {
                                    Test-NetConnection -Port $Tst_ntconnect_port -InformationLevel $InfoLvl
                               }
                               #Test TCP connectivity and display detailed results
                               elif ($Tst_ntconnect_port -eq "none" -and $InfoLvl -ne 0) {
                                    Test-NetConnection -InformationLevel $InfoLvl
                               }

                               elif ($Tst_ntconnect_port -ne "none" -and $InfoLvl -eq 0) {
                                    Test-NetConnection -Port $Tst_ntconnect_port -InformationLevel $InfoLvl
                               }
                            }

                            '2' {
                               Read-Host "test 2"
                            }
                            'q' {
                                return
                            }
                        }
                 }
                 until ($input -eq 'q')
                 
            } 
            ‘q’ {
                 return
            }
            }
            pause
 }
 until ($input -eq ‘q’)