$InformationPreference = "Continue"

if(Get-Module -Name solliance-synapse-automation){
        Remove-Module solliance-synapse-automation
}
Import-Module "..\solliance-synapse-automation"

$IsCloudLabs = Test-Path C:\LabFiles\AzureCreds.ps1;

$selectedSubName = "Synapse Analytics Demos and Labs"

if($IsCloudLabs)
{
    Connect-AzAccount;
    Select-AzSubscription -SubscriptionName $selectedSubName;
    $subscriptionId = (Get-AzContext).Subscription.Id
    $tenantId = (Get-AzContext).Tenant.Id;
    $global:logindomain = (Get-AzContext).Tenant.Id;
}
else
{
    #az login
    az account set --subscription $selectedSubName;
    $res = ((az account show) | ConvertFrom-Json)
    $subscriptionId = $res.Id;
    $tenantId = $res.tenantId;
    $global:logindomain = $res.tenantId;
}

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""

$global:tokenTimes = [ordered]@{
        Synapse = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
}

AutoPauseAll $subscriptionId;