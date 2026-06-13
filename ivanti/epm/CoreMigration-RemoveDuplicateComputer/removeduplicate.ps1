# http://localhost/MBSDKService/MsgSDK.asmx?WSDL/GetMachineData
 
$mycreds = Get-Credential -Credential "Domain\account"
 
$ldWSold    = New-WebServiceProxy -uri http://oldcore.example.com/MBSDKService/MsgSDK.asmx -Credential $mycreds
$ListOlds   = $ldWSold.ListMachines("").Devices
 
$ldWSNew    = New-WebServiceProxy -uri https://newcore.example.com/MBSDKService/MsgSDK.asmx -Credential $mycreds
$ListNews   = $ldWSNew.ListMachines("").Devices
  
#GUID                                   DeviceName      DomainName           LastLogin
foreach ($ListOld in $ListOlds) {
    foreach ($ListNew in $ListNews) {
        If ($ListNew.DeviceName -notlike "newcore*") {
            If ($ListOld.DeviceName -eq $ListNew.DeviceName) {
                If ($ListOld.GUID -ne "Unassigned") {
                    write-host $ListOld.DeviceName "=>" $ListOld.GUID                
                    $ldWSold.DeleteComputerByGUID($ListOld.GUID)
                }
            }
        }
    }
}