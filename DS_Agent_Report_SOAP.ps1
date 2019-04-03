Clear-Host
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$Config = (Get-Content "$PSScriptRoot\DS-Config.json" -Raw) | ConvertFrom-Json

$Manager = $Config.MANAGER
$Port = $Config.PORT
$Tenant = $Config.TENANT
$UserName = $Config.USER_NAME
$Password = $Config.PASSWORD
$REPORTFILE = $Config.REPORTFILE

$ErrorActionPreference = 'Stop'

$WSDL = "/webservice/Manager?WSDL"
$DSM_URI = "https://" + $Manager + ":" + $Port + $WSDL
$objManager = New-WebServiceProxy -uri $DSM_URI -namespace WebServiceProxy -class DSMClass

Write-Host "[INFO]	Connecting to DSM server $DSM_URI"
try{
	if (!$Tenant) {
		$sID = $objManager.authenticate($UserName,$Password)
	}
	else {
		$sID = $objManager.authenticateTenant($Tenant,$UserName,$Password)
	}
	Remove-Variable UserName
	Remove-Variable Password
	Remove-Variable Tenant
	Write-Host "[INFO]	Connection to DSM server $DSM_URI was SUCCESSFUL"
}
catch{
	Write-Host "[ERROR]	Failed to logon to $DSM_URI.	$_"
	Remove-Variable UserName
	Remove-Variable Password
	Remove-Variable Tenant
	Exit
}

$ReportHeader = 'Host_ID, HostName, DisplayName, AgentOS, InstanceID, AgentStatus, AgentVersion, PolicyName, CurrentAMPatternVersion, AntiMalwarePatternVersion, LastSuccessfulUpdate, AntiMalwareState'
Add-Content -Path $REPORTFILE -Value $ReportHeader

$ComponentSummary = $objManager.componentSummaryRetrieve($sID)
foreach ($item in $ComponentSummary){
    #$ComponentID = $item.id
    $ComponentType = $item.type
    #$ComponentName = $item.name
    $ComponentVersion = $item.currentVersion
   # Write-Host "$ComponentID, $ComponentType, $ComponentName, $ComponentVersion"

    If ($ComponentType -eq "1208090624"){
        $CurrentAMPatternVersion = $ComponentVersion
        break
    }
}

$Groups = $objManager.hostGroupRetrieveAll($sID)
foreach ($Group in $Groups) {
	$hostsPerGroup = $objManager.hostRetrieveByHostGroup($Group.ID, $sID)
	Foreach ($Item in $hostsPerGroup){
        $HostStatus = $objManager.hostDetailRetrieveByName($Item.Name, "HIGH", $sID)
        $Host_ID            = $Item.ID
        $HostName           = $Item.Name
        $DisplayName        = $HostStatus.displayName
        $AgentStatus        =  $HostStatus.OverallStatus
		$AgentVersion       = $HostStatus.overallVersion
		$PolicyName         = $HostStatus.securityProfileName
        $AgentOS            = $HostStatus.Platform
        $InstanceID         = $HostStatus.cloudObjectInstanceId
        $AntiMalwareState   = $HostStatus.overallAntiMalwareStatus
        $AntiMalwarePatternVersion  = $HostStatus.antiMalwareSmartScanPatternVersion
        $LastSuccessfulUpdate       = $HostStatus.overallLastSuccessfulUpdate

        $ReportData =  "$Host_ID, $HostName, $DisplayName, $AgentOS, $InstanceID, $AgentStatus, $AgentVersion, $PolicyName, $CurrentAMPatternVersion, $AntiMalwarePatternVersion, $LastSuccessfulUpdate, $AntiMalwareState"
        Add-Content -Path $REPORTFILE -Value $ReportData
        #Write-Host $ReportData
	}
}

