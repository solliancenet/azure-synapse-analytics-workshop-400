Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser
# Install-Module -Name Az.CosmosDB -AllowClobber -Scope CurrentUser
# Import-Module Az.CosmosDB

Connect-AzAccount
$uniqueId = "03"

$subscriptionId = "cccbcfbd-0a1f-45ee-b948-2393697c32b0"
$resourceGroupName = "Synapse-L400-Workshop-175799"
$templatesPath = ".\artifacts\environment-setup\templates"
$datasetsPath = ".\artifacts\environment-setup\datasets"
$pipelinesPath = ".\artifacts\environment-setup\pipelines"
$workspaceName = "asaworkspace$($uniqueId)"
$cosmosDbAccountName = "asacosmosdb$($uniqueId)"
$cosmosDbDatabase = "CustomerProfile"
$cosmosDbContainer = "OnlineUserProfile01"
$dataLakeAccountName = "asadatalake$($uniqueId)"
$blobStorageAccountName = "asastore$($uniqueId)"
$keyVaultName = "asakeyvault$($uniqueId)"

$synapseToken = "..."
$managementToken = "..."


$result = Create-KeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $keyVaultName -Token $synapseToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$result = Create-IntegrationRuntime -TemplatesPath $templatesPath -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name "AzureIntegrationRuntime01" -CoreCount 16 -TimeToLive 60 -Token $managementToken
Start-Sleep -Seconds 20
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$cosmosDbAccountKey = List-CosmosDBKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $cosmosDbAccountName -Token $managementToken
$result = Create-CosmosDBLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $cosmosDbAccountName -Database $cosmosDbDatabase -Key $cosmosDbAccountKey -Token $synapseToken
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

