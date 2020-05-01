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
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$result = Create-IntegrationRuntime -TemplatesPath $templatesPath -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name "AzureIntegrationRuntime01" -CoreCount 16 -TimeToLive 60 -Token $managementToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$dataLakeAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Token $managementToken
$result = Create-DataLakeLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $dataLakeAccountName  -Key $dataLakeAccountKey -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$blobStorageAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $blobStorageAccountName -Token $managementToken
$result = Create-BlobStorageLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $blobStorageAccountName  -Key $blobStorageAccountKey -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

Write-Information "Start the $($sqlPoolName) SQL pool if needed."

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Token $managementToken
if ($result.properties.status -ne "Online") {
    Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action resume -Token $managementToken
    Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online -Token $managementToken
}

Write-Information "Scale up the $($sqlPoolName) SQL pool to DW3000c to prepare for baby MOADs import."

Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW3000c -Token $managementToken
Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online -Token $managementToken

Write-Information "Create SQL logins in master SQL pool"

$params = @{ PASSWORD = $sqlPassword }
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName "master" -FileName "01-create-logins" -Parameters $params -Token $synapseSQLToken
$result

Write-Information "Create SQL users and role assignments in $($sqlPoolName)"

$params = @{ USER_NAME = $userName }
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "02-create-users" -Parameters $params -Token $synapseSQLToken
$result

Write-Information "Create schemas in $($sqlPoolName)"

$params = @{}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "03-create-schemas" -Parameters $params -Token $synapseSQLToken
$result

Write-Information "Create tables in the [wwi] schema in $($sqlPoolName)"

$params = @{}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "04-create-tables-in-wwi-schema" -Parameters $params -Token $synapseSQLToken
$result


Write-Information "Create tables in the [wwi_ml] schema in $($sqlPoolName)"

$dataLakeAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Token $managementToken
$params = @{ 
        DATA_LAKE_ACCOUNT_NAME = $dataLakeAccountName  
        DATA_LAKE_ACCOUNT_KEY = $dataLakeAccountKey 
}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "05-create-tables-in-wwi-ml-schema" -Parameters $params -Token $synapseSQLToken
$result


Write-Information "Create tables in the [wwi_security] schema in $($sqlPoolName)"

$params = @{ 
        DATA_LAKE_ACCOUNT_NAME = $dataLakeAccountName  
}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "06-create-tables-in-wwi-security-schema" -Parameters $params -Token $synapseSQLToken
$result


Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.admin"

$linkedServiceName = $sqlPoolName.ToLower()
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                 -UserName "asa.sql.admin" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.highperf"

$linkedServiceName = "$($sqlPoolName.ToLower())_highperf"
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                 -UserName "asa.sql.highperf" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

Write-Information "Create data sets for data load in SQL pool $($sqlPoolName)"

$datasets = @{
        wwi02_date_adls = $dataLakeAccountName
        wwi02_product_adls = $dataLakeAccountName
        wwi02_sale_small_adls = $dataLakeAccountName
        wwi02_date_asa = $sqlPoolName.ToLower()
        wwi02_product_asa = $sqlPoolName.ToLower()
        wwi02_sale_small_asa = "$($sqlPoolName.ToLower())_highperf"
}

foreach ($dataset in $datasets.Keys) {
        Write-Information "Creating dataset $($dataset))"
        $result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $dataset -LinkedServiceName $datasets[$dataset] -Token $synapseToken
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken
}


Write-Information "Create Setup - Load SQL Pool pipeline"

$params = @{
        BLOB_STORAGE_LINKED_SERVICE_NAME = $blobStorageAccountName
}
$name = "Setup - Load SQL Pool"
$fileName = "load_sql_pool_from_data_lake"
$result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $name -FileName $fileName -Parameters $params -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$result = Run-Pipeline -WorkspaceName $workspaceName -Name $name -Token $synapseToken
$result = Wait-ForPipelineRun -WorkspaceName $workspaceName -RunId $result.runId -Token $synapseToken
$result

Write-Information "Create tables in wwi_perf schema in SQL pool $($sqlPoolName)"

$params = @{}

# Since these are potentially long running, we'll force a token reissue to avoid failed logins

$script = "07-create-wwi-perf-sale-heap"
Write-Information $script
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
$synapseSQLToken = $result.access_token
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -Parameters $params -Token $synapseSQLToken

$script = "08-create-wwi-perf-sale-partition01"
Write-Information $script
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
$synapseSQLToken = $result.access_token
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -Parameters $params -Token $synapseSQLToken

$script = "09-create-wwi-perf-sale-partition02"
Write-Information $script
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
$synapseSQLToken = $result.access_token
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -Parameters $params -Token $synapseSQLToken

$script = "10-create-wwi-perf-sale-index"
Write-Information $script
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
$synapseSQLToken = $result.access_token
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -Parameters $params -Token $synapseSQLToken

$script = "11-create-wwi-perf-sale-hash-ordered"
Write-Information $script
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
$synapseSQLToken = $result.access_token
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -Parameters $params -Token $synapseSQLToken

$script = "12-create-wwi-perf-sale-hash-projection"
Write-Information $script
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
$synapseSQLToken = $result.access_token
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -Parameters $params -Token $synapseSQLToken

$script = "13-create-wwi-perf-sale-hash-projection2"
Write-Information $script
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
$synapseSQLToken = $result.access_token
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -Parameters $params -Token $synapseSQLToken

$script = "14-create-wwi-perf-sale-hash-projection-big"
Write-Information $script
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
$synapseSQLToken = $result.access_token
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -Parameters $params -Token $synapseSQLToken

$script = "15-create-wwi-perf-sale-hash-projection-big2"
Write-Information $script
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
$synapseSQLToken = $result.access_token
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -Parameters $params -Token $synapseSQLToken


Write-Information "Scale down the $($sqlPoolName) SQL pool to DW1000c after baby MOADs import."

Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW1000c -Token $managementToken
Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online -Token $managementToken












#
# =============== COSMOS DB IMPORT - MUST REMAIN LAST IN SCRIPT !!! ====================
#                         


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
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$cosmosDbAccountKey = List-CosmosDBKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $cosmosDbAccountName -Token $managementToken
$result = Create-CosmosDBLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $cosmosDbAccountName -Database $cosmosDbDatabase -Key $cosmosDbAccountKey -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "customer_profile_cosmosdb"
$result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $name -LinkedServiceName $cosmosDbAccountName -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "Setup - Import User Profile Data into Cosmos DB"
$fileName = "import_customer_profiles_into_cosmosdb"
$result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $name -FileName $fileName -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$result = Run-Pipeline -WorkspaceName $workspaceName -Name $name -Token $synapseToken
$result = Wait-ForPipelineRun -WorkspaceName $workspaceName -RunId $result.runId -Token $synapseToken
$result

#
# =============== WAIT HERE FOR PIPELINE TO FINISH - MIGHT TAKE ~45 MINUTES ====================
#                         
#                    COPY 722647 records to CosmosDB ==> SELECT VALUE COUNT(1) FROM C
#

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
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "customer_profile_cosmosdb"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $name -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "wwi02_online_user_profiles_01_adal"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $name -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = $cosmosDbAccountName
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "linkedServices" -Name $name -Token $synapseToken
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken
