Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

$InformationPreference = "Continue"

# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser
# Install-Module -Name Az.CosmosDB -AllowClobber -Scope CurrentUser
# Import-Module Az.CosmosDB

#
# TODO: Keep all required configuration in C:\LabFiles\AzureCreds.ps1 file
. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName                # READ FROM FILE
$password = $AzurePassword                # READ FROM FILE
$clientId = $TokenGeneratorClientId       # READ FROM FILE
$sqlPassword = $AzureSQLPassword          # READ FROM FILE

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*L400*" }).ResourceGroupName
$uniqueId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id

$templatesPath = ".\artifacts\environment-setup\templates"
$datasetsPath = ".\artifacts\environment-setup\datasets"
$pipelinesPath = ".\artifacts\environment-setup\pipelines"
$sqlScriptsPath = ".\artifacts\environment-setup\sql"
$workspaceName = "asaworkspace$($uniqueId)"
$cosmosDbAccountName = "asacosmosdb$($uniqueId)"
$cosmosDbDatabase = "CustomerProfile"
$cosmosDbContainer = "OnlineUserProfile01"
$dataLakeAccountName = "asadatalake$($uniqueId)"
$blobStorageAccountName = "asastore$($uniqueId)"
$keyVaultName = "asakeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASA"
$sqlPoolName = "SQLPool01"
$integrationRuntimeName = "AzureIntegrationRuntime01"
$sparkPoolName = "SparkPool01"
$amlWorkspaceName = "amlworkspace$($uniqueId)"


$ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
$global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
$global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
$global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""

$global:tokenTimes = [ordered]@{
        Synapse = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
}

Write-Information "Creating Spark notebooks..."

$notebooks = [ordered]@{
        "Setup - Probe" = ".\artifacts\environment-setup\notebooks\Setup - Probe.ipynb"
        "Activity 05 - Model Training" = ".\artifacts\day-03\Activity 05 - Model Training.ipynb"
        "Lab 06 - Machine Learning" = ".\artifacts\day-03\lab-06-machine-learning\Lab 06 - Machine Learning.ipynb"
        "Lab 07 - Spark ML" = ".\artifacts\day-03\lab-07-spark-ml\Lab 07 - Spark ML.ipynb"
}

$cellParams = [ordered]@{
        "#SQL_POOL_NAME#" = $sqlPoolName
        "#SUBSCRIPTION_ID#" = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $resourceGroupName
        "#AML_WORKSPACE_NAME#" = $amlWorkspaceName
}

foreach ($notebookName in $notebooks.Keys) {
        Write-Information "Creating notebook $($notebookName)"
        
        $result = Create-SparkNotebook -TemplatesPath $templatesPath -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName `
                -WorkspaceName $workspaceName -SparkPoolName $sparkPoolName -Name $notebookName -NotebookFileName $notebooks[$notebookName] -CellParams $cellParams
        $result = Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
        $result
}

$result = Start-SparkNotebookSession -TemplatesPath $templatesPath -WorkspaceName $workspaceName -SparkPoolName $sparkPoolName -NotebookName $notebookName
$result2 = Get-SparkNotebookSession -WorkspaceName $workspaceName -SparkPoolName $sparkPoolName -SessionId $result.id
$result2

Write-Information "Create SQL scripts for Lab 05"

$sqlScripts = [ordered]@{
        "Lab 05 - Exercise 3 - Column Level Security" = ".\artifacts\day-02\lab-05-security"
        "Lab 05 - Exercise 3 - Dynamic Data Masking" = ".\artifacts\day-02\lab-05-security"
        "Lab 05 - Exercise 3 - Row Level Security" = ".\artifacts\day-02\lab-05-security"
}

foreach ($sqlScriptName in $sqlScripts.Keys) {
        $sqlScriptFileName = "$($sqlScripts[$sqlScriptName])\$($sqlScriptName).sql"
        #Write-Information "Creating SQL script $($sqlScriptName) from $($sqlScriptFileName)"
        #$result = Create-SQLScript -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $sqlScriptName -TemplateFileName "sql_script" -ScriptFileName $sqlScriptFileName -Token $synapseToken
        #Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken
}
