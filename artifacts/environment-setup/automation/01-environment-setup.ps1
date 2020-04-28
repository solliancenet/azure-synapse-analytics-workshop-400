Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

Install-Module -Name Az -AllowClobber -Scope CurrentUser
Install-Module -Name Az.CosmosDB -AllowClobber -Scope CurrentUser

Import-Module Az.CosmosDB

Connect-AzAccount

$subscriptionId = "cccbcfbd-0a1f-45ee-b948-2393697c32b0"
$resourceGroupName = "Synapse-L400-Workshop-175799"
$templatesPath = ".\artifacts\environment-setup\templates"
$datasetsPath = ".\artifacts\environment-setup\datasets"
$pipelinesPath = ".\artifacts\environment-setup\pipelines"
$workspaceName = "asaworkspace03"
$cosmosDbAccountName = "asacosmosdb03"
$cosmosDbDatabase = "CustomerProfile"
$cosmosDbContainer = "OnlineUserProfile01"
$dataLakeAccountName = "asadatalake03"
$blobStorageAccountName = "asastore03"
$keyVaultName = "asakeyvault03"

$synapseToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IkN0VHVoTUptRDVNN0RMZHpEMnYyeDNRS1NSWSIsImtpZCI6IkN0VHVoTUptRDVNN0RMZHpEMnYyeDNRS1NSWSJ9.eyJhdWQiOiJodHRwczovL2Rldi5henVyZXN5bmFwc2UubmV0IiwiaXNzIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvY2VmY2I4ZTctZWUzMC00OWI4LWIxOTAtMTMzZjFkYWFmZDg1LyIsImlhdCI6MTU4ODA3MTI3MywibmJmIjoxNTg4MDcxMjczLCJleHAiOjE1ODgwNzUxNzMsImFjciI6IjEiLCJhaW8iOiJBU1FBMi84UEFBQUFyYzI3bGlQMGZ6b2tINVV1Nk1BaXQrb0pZVGwrVmdIK3ZrL1lOV0d1MUJjPSIsImFtciI6WyJwd2QiXSwiYXBwaWQiOiJlYzUyZDEzZC0yZTg1LTQxMGUtYTg5YS04Yzc5ZmI2YTMyYWMiLCJhcHBpZGFjciI6IjAiLCJmYW1pbHlfbmFtZSI6IjE3NTc5OSIsImdpdmVuX25hbWUiOiJPRExfVXNlciIsImlwYWRkciI6Ijc5LjExOC4xLjIyMyIsIm5hbWUiOiJPRExfVXNlciAxNzU3OTkiLCJvaWQiOiIzNzJiN2Q1MS0xNmE0LTQ0NjctOTZlOS1jMTY5ZGUwNTQxYTMiLCJwdWlkIjoiMTAwMzIwMDBCNzQ5Qzk4QSIsInNjcCI6IndvcmtzcGFjZWFydGlmYWN0cy5tYW5hZ2VtZW50Iiwic3ViIjoiQnQ5XzFIc2QxWk5fMk1BVnJZUkd1SnZpRHhDc2JyM3V3UG9jRjRWbFFfYyIsInRpZCI6ImNlZmNiOGU3LWVlMzAtNDliOC1iMTkwLTEzM2YxZGFhZmQ4NSIsInVuaXF1ZV9uYW1lIjoib2RsX3VzZXJfMTc1Nzk5QG1zYXp1cmVsYWJzLm9ubWljcm9zb2Z0LmNvbSIsInVwbiI6Im9kbF91c2VyXzE3NTc5OUBtc2F6dXJlbGFicy5vbm1pY3Jvc29mdC5jb20iLCJ1dGkiOiJsdGFKX1I1cFJrYXpITGRQUTFTVkFBIiwidmVyIjoiMS4wIn0.W1Dy07kH0vaimMARO0YYhHuSCfg4ys26rwmwKQmqjhB5LNS4PVkKWxpLA1391yFMp116oRiHUOiCPBACiMNTffU3L-MMtY0WUjyco8hQc-P9Fd1ZxRb-bdz6gelJ5MYlJzfoW4OttNfZfwbItW7RzL7htks0p55h1MLUrlcdqMxQrrVKSh7qdlOxr6BUpEYriDGHG3W41rV0IveAIbHDZSf-pEWRnQC6D72SI0ygUKW2flImnPNqa3tCTffMVIm8-StgqQOpK3TDvPViZzGIWJ3ilJ3WrPl069juq9a_0H4DXJpLAURF-m-8YGlls_sslDgt_n7hCwTO6Yu6BHblMA"
$managementToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IkN0VHVoTUptRDVNN0RMZHpEMnYyeDNRS1NSWSIsImtpZCI6IkN0VHVoTUptRDVNN0RMZHpEMnYyeDNRS1NSWSJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuY29yZS53aW5kb3dzLm5ldC8iLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9jZWZjYjhlNy1lZTMwLTQ5YjgtYjE5MC0xMzNmMWRhYWZkODUvIiwiaWF0IjoxNTg4MDc4NTgxLCJuYmYiOjE1ODgwNzg1ODEsImV4cCI6MTU4ODA4MjQ4MSwiYWNyIjoiMSIsImFpbyI6IjQyZGdZSEJybTNYdmlKN2VJYTNvclAycDZ4OW9pT1NsYTZYZk5EbmhVTVQ1ZS9JYmt4b0EiLCJhbXIiOlsicHdkIl0sImFwcGlkIjoiZWM1MmQxM2QtMmU4NS00MTBlLWE4OWEtOGM3OWZiNmEzMmFjIiwiYXBwaWRhY3IiOiIwIiwiZmFtaWx5X25hbWUiOiIxNzU3OTkiLCJnaXZlbl9uYW1lIjoiT0RMX1VzZXIiLCJpcGFkZHIiOiI3OS4xMTguMS4yMjMiLCJuYW1lIjoiT0RMX1VzZXIgMTc1Nzk5Iiwib2lkIjoiMzcyYjdkNTEtMTZhNC00NDY3LTk2ZTktYzE2OWRlMDU0MWEzIiwicHVpZCI6IjEwMDMyMDAwQjc0OUM5OEEiLCJzY3AiOiJ1c2VyX2ltcGVyc29uYXRpb24iLCJzdWIiOiJaeG5IdHJ2dTlFbVlTWF9HV3J3UnU4U1EwSVJpa2RwOVJSNWhXX2lReDRVIiwidGlkIjoiY2VmY2I4ZTctZWUzMC00OWI4LWIxOTAtMTMzZjFkYWFmZDg1IiwidW5pcXVlX25hbWUiOiJvZGxfdXNlcl8xNzU3OTlAbXNhenVyZWxhYnMub25taWNyb3NvZnQuY29tIiwidXBuIjoib2RsX3VzZXJfMTc1Nzk5QG1zYXp1cmVsYWJzLm9ubWljcm9zb2Z0LmNvbSIsInV0aSI6IjdpR0dlTmhRSzBhQUFWZmpPVnlwQUEiLCJ2ZXIiOiIxLjAifQ.n7E9Yj-ePLiKMl6ScT9VruAH4h0JujPCeeU4yOK8GDxlZ4NJ25xZ5Zdxu-GxtM3bg6Bd8OSku_FQ7IvGF8JbP45BVAsdJp7Uvsn84nmVTiWHAlrI-NpSIh3gVLgvfFHTZ0iLJbPNXfgncAcRA0B_cj-T_FCIZkZbYe5czddiGXZ0phQ71q4-vY6HA3bcSSqtLABbbVO1b7xEkONlFB20EJeM5PTPqgbU-9ibO_ng-W2Gvrd8iojQbVH4TdaHv9-ttYp4nAQdSx5SdqvJWdYUzmIsuXc-tGRYCS0QRPXR6tgR1CJnWQN4k_OzkeA3C97W-e8ZRyyWupr6YCCrFTid4w"


Create-KeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $keyVaultName -Token $synapseToken

Create-IntegrationRuntime -TemplatesPath $templatesPath -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name "AzureIntegrationRuntime01" -CoreCount 16 -TimeToLive 60 -Token $managementToken

$cosmosDbAccountKey = List-CosmosDBKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $cosmosDbAccountName -Token $managementToken

$result = Create-CosmosDBLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $cosmosDbAccountName -Database $cosmosDbDatabase -Key $cosmosDbAccountKey -Token $synapseToken
$result

$dataLakeAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -Token $managementToken

$result = Create-DataLakeLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $dataLakeAccountName  -Key $dataLakeAccountKey -Token $synapseToken
$result

$blobStorageAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $blobStorageAccountName -Token $managementToken
$result = Create-BlobStorageLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $dataLakeAccountName  -Key $dataLakeAccountKey -Token $synapseToken
$result

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
$result

$name = "customer_profile_cosmosdb"
$result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $name -LinkedServiceName $cosmosDbAccountName -Token $synapseToken
$result

Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "Setup - Import User Profile Data into Cosmos DB"
$fileName = "import_customer_profiles_into_cosmosdb"
$result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $name -FileName $fileName -Token $synapseToken
$result

$result = Run-Pipeline -WorkspaceName $workspaceName -Name $name -Token $synapseToken
$result

Get-PipelineRun -WorkspaceName $workspaceName -RunId $result.runId -Token $synapseToken


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
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "customer_profile_cosmosdb"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $name -Token $synapseToken
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken

$name = "wwi02_online_user_profiles_01_adal"
$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $name -Token $synapseToken
Get-OperationResult -WorkspaceName $workspaceName -OperationId $result.operationId -Token $synapseToken