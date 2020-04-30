Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

$InformationPreference = "Continue"

# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser
# Install-Module -Name Az.CosmosDB -AllowClobber -Scope CurrentUser
# Import-Module Az.CosmosDB

Connect-AzAccount
$uniqueId = "176496"

$tenantId = "cefcb8e7-ee30-49b8-b190-133f1daafd85"
$subscriptionId = "c8ffc575-49c1-41ae-aa40-67f9995acb33"
$resourceGroupName = "Synapse-L400-Workshop-$($uniqueId)"
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
$sqlPoolName = "SQLPool01"

$userName = Read-Host "User name"
$password = Read-Host "Password"
$clientId = Read-Host "Client id"
$sqlPassword = Read-Host "SQL password"


$ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
$ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
$ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
$ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"

$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapse -ContentType "application/x-www-form-urlencoded"
$synapseToken = $result.access_token
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
$synapseSQLToken = $result.access_token
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodyManagement -ContentType "application/x-www-form-urlencoded"
$managementToken = $result.access_token


$result = Create-KeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $keyVaultName -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$result = Create-IntegrationRuntime -TemplatesPath $templatesPath -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name "AzureIntegrationRuntime01" -CoreCount 16 -TimeToLive 60 -Token $managementToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$dataLakeAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Token $managementToken
$result = Create-DataLakeLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $dataLakeAccountName  -Key $dataLakeAccountKey -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$blobStorageAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $blobStorageAccountName -Token $managementToken
$result = Create-BlobStorageLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $dataLakeAccountName  -Key $dataLakeAccountKey -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

# Increase RUs in CosmosDB container

$container = Get-AzCosmosDBSqlContainer `
        -ResourceGroupName $resourceGroupName `
        -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
        -Name $cosmosDbContainer

Set-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
        -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
        -Name $cosmosDbContainer -Throughput 5000 `
        -PartitionKeyKind $container.Resource.PartitionKey.Kind `
        -PartitionKeyPath $container.Resource.PartitionKey.Paths

$name = "wwi02_online_user_profiles_01_adal"
$result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $name -LinkedServiceName $dataLakeAccountName -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$cosmosDbAccountKey = List-CosmosDBKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $cosmosDbAccountName -Token $managementToken
$result = Create-CosmosDBLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $cosmosDbAccountName -Database $cosmosDbDatabase -Key $cosmosDbAccountKey -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "customer_profile_cosmosdb"
$result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $name -LinkedServiceName $cosmosDbAccountName -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "Setup - Import User Profile Data into Cosmos DB"
$fileName = "import_customer_profiles_into_cosmosdb"
$result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $name -FileName $fileName -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$result = Run-Pipeline -WorkspaceName $workspaceName -Name $name -Token $synapseToken
Get-PipelineRun -WorkspaceName $workspaceName -RunId $result.runId -Token $synapseToken

#!!!!!! Stop here and wait for the pipeline execution to finish

$container = Get-AzCosmosDBSqlContainer `
        -ResourceGroupName $resourceGroupName `
        -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
        -Name $cosmosDbContainer

Set-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
        -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
        -Name $cosmosDbContainer -Throughput 400 `
        -PartitionKeyKind $container.Resource.PartitionKey.Kind `
        -PartitionKeyPath $container.Resource.PartitionKey.Paths

$name = "Setup - Import User Profile Data into Cosmos DB"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "pipelines" -Name $name -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "customer_profile_cosmosdb"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $name -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "wwi02_online_user_profiles_01_adal"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $name -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "asacosmosdb03"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "linkedServices" -Name $name -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

Write-Information "Start the $($sqlPoolName) SQL pool if needed."

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Token $managementToken
if ($result.properties.status -ne "Online") {
        Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action pause -Token $managementToken
        $result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Paused -Token $managementToken
}

Write-Information "Scale up the $($sqlPoolName) SQL pool to DW3000c to prepare for baby MOADs import."

Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW3000c -Token $managementToken
$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online -Token $managementToken

Write-Information "Scale down the $($sqlPoolName) SQL pool to DW1000c after baby MOADs import."

Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW1000c -Token $managementToken
$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online -Token $managementToken


Write-Information "Create SQL logins on master SQL pool"

$params = @{ PASSWORD = $sqlPassword }
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName "master" -FileName "01-create-logins" -Parameters $params -Token $synapseSQLToken
$result

Write-Information "Create SQL users and role assignments on master SQL pool"

$params = @{ USER_NAME = $userName }
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "02-create-users" -Parameters $params -Token $synapseSQLToken
$result

