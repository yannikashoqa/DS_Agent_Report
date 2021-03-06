Clear-Host
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$ErrorActionPreference = 'Stop'

$Config                 = (Get-Content "$PSScriptRoot\DS-Config.json" -Raw) | ConvertFrom-Json
$Manager                = $Config.MANAGER
$Port                   = $Config.PORT
$Tenant                 = $Config.TENANT
$UserName               = $Config.USER_NAME
$Password               = $Config.PASSWORD
$REPORTNAME             = $Config.REPORTNAME
$REGIONS                = $Config.REGION
$AWSToolsforPowerShell  = $Config.AWSTOOLSFORPOWERSHELL
$AWSCredentialProfile   = $Config.AWSCREDENTIALPROFILE


$WSDL       = "/webservice/Manager?WSDL"
$DSM_URI    = "https://" + $Manager + ":" + $Port + $WSDL
$objManager = New-WebServiceProxy -uri $DSM_URI -namespace WebServiceProxy -class DSMClass
$REPORTFILE = $REPORTNAME + ".csv"

$StartTime  = $(get-date)

Function Get-InstanceInfo{
    param (	[parameter(Mandatory=$true)] $InstanceID )

    [hashtable]$InstanceInfo = @{}
    $InstanceID = $InstanceID
    Foreach ($Region in $REGIONS){
        $InstancesPerRegion = (Get-EC2Instance -Region $Region).Instances
        Foreach ($Item in $InstancesPerRegion){
            If ($InstanceID-eq $Item.InstanceID){
                $EC2InstanceStatus = Get-EC2InstanceStatus -InstanceId $InstanceID -Region $Region
                $InstanceInfo.Region = $Region
                $InstanceInfo.State = $EC2InstanceStatus.InstanceState.Name
                #Need to check since nothing is returned if the instance is powered off
                If ($Null -eq $InstanceInfo.State){
                    $InstanceInfo.State = "Stopped"
                }
                $MatchFound = $True
                Return $InstanceInfo
                Break
            }
        }
        If ($MatchFound){
            Break
        }
    }
}

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

if ((Test-Path $REPORTFILE) -eq $true){
    $BackupDate         = get-date -format MMddyyyy-HHmm
    $BackupReportName   = $REPORTNAME + "_" + $BackupDate + ".csv"
    copy-item -Path $REPORTFILE -Destination $BackupReportName
    Remove-item $REPORTFILE
}

$ReportHeader = 'GroupName, Host_ID, HostName, DisplayName, AgentOS, InstanceID, InstanceState, AgentStatus, AgentVersion, PolicyName, ParentPolicyName, CurrentAMPatternVersion, AntiMalwarePatternVersion, LastSuccessfulUpdate, AntiMalwareState'
Add-Content -Path $REPORTFILE -Value $ReportHeader

$ComponentSummary = $objManager.componentSummaryRetrieve($sID)
foreach ($item in $ComponentSummary){
    $ComponentType      = $item.type
    $ComponentVersion   = $item.currentVersion
    If ($ComponentType -eq "1208090624"){
        $CurrentAMPatternVersion = $ComponentVersion
        break
    }
}

$HostFilterTransport = New-Object -TypeName WebServiceProxy.HostFilterTransport
$HostFilterTransport.Set_Type("ALL_HOSTS")
$AllHost = $objManager.hostDetailRetrieve($HostFilterTransport, "LOW", $sID)
Foreach ($Item in $AllHost){
    $Host_ID                    = $Item.ID
    $HostName                   = $Item.Name
    $DisplayName                = $Item.displayName
    $GroupName                  = $Item.hostGroupName
    $AgentStatus                = $Item.OverallStatus
    $AgentVersion               = $Item.overallVersion
    $PolicyName                 = $Item.securityProfileName
    $AgentOS                    = $Item.Platform
    $InstanceID                 = $Item.cloudObjectInstanceId
    $AntiMalwareState           = $Item.overallAntiMalwareStatus
    $AntiMalwarePatternVersion  = $Item.antiMalwareSmartScanPatternVersion
    $LastSuccessfulUpdate       = $Item.overallLastSuccessfulUpdate

    $objCurrentSecurityProfile  = $objManager.securityProfileRetrieveByName($PolicyName,$sID)
    $ParentSecurityProfileID    = $objCurrentSecurityProfile.parentSecurityProfileID
    $objParentSecurityProfile   = $objManager.securityProfileRetrieve($ParentSecurityProfileID,$sID)
    $ParentPolicyName           = $objParentSecurityProfile.name

    If ($Null -ne $InstanceID -AND $AWSToolsforPowerShell -eq "Yes"){
        Set-AWSCredential -ProfileName $AWSCredentialProfile
        $InstanceInfo = Get-InstanceInfo -InstanceID $InstanceID
        $InstanceState = $InstanceInfo.State
    }

    $ReportData =  "$GroupName, $Host_ID, $HostName, $DisplayName, $AgentOS, $InstanceID, $InstanceState, $AgentStatus, $AgentVersion, $PolicyName, $ParentPolicyName, $CurrentAMPatternVersion, $AntiMalwarePatternVersion, $LastSuccessfulUpdate, $AntiMalwareState"
    Add-Content -Path $REPORTFILE -Value $ReportData
    $InstanceState = $Null
    #Write-Host $ReportData
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)

Write-Host "Report Generation is Complete.  It took $totalTime"
