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

$overallStateIsValid = $true

$asaArtifacts = [ordered]@{

        "wwi02_sale_small_workload_01_asa" = @{ 
                Category = "datasets"
                Valid = $false
        }
        "wwi02_sale_small_workload_02_asa" = @{ 
                Category = "datasets"
                Valid = $false
        }
        "Lab 08 - Execute Business Analyst Queries" = @{
                Category = "pipelines"
                Valid = $false
        }
        "Lab 08 - Execute Data Analyst and CEO Queries" = @{
                Category = "pipelines"
                Valid = $false
        }
        "Lab 06 - Machine Learning" = @{
                Category = "notebooks"
                Valid = $false
        }
        "Lab 07 - Spark ML" = @{
                Category = "notebooks"
                Valid = $false
        }
        "Activity 05 - Model Training" = @{
                Category = "notebooks"
                Valid = $false
        }
}

foreach ($asaArtifactName in $asaArtifacts.Keys) {
        try {
                Write-Information "Checking $($asaArtifactName) in $($asaArtifacts[$asaArtifactName]["Category"])"
                $result = Get-ASAObject -WorkspaceName $workspaceName -Category $asaArtifacts[$asaArtifactName]["Category"] -Name $asaArtifactName
                $asaArtifacts[$asaArtifactName]["Valid"] = $true
                Write-Information "OK"
        }
        catch { 
                Write-Warning "Not found!"
                $overallStateIsValid = $false
        }
}

# the $asaArtifacts contains the current status of the workspace

$tables = [ordered]@{
        "wwi.Date" = @{
                Count = 3652
                Valid = $false
                ValidCount = $false
        }
        "wwi.Product" = @{
                Count = 5000
                Valid = $false
                ValidCount = $false
        }
        "wwi.SaleSmall" = @{
                Count = 2903451490
                Valid = $false
                ValidCount = $false
        }
        "wwi_perf.Sale_Hash_Ordered" = @{
                Count = 2903451490
                Valid = $false
                ValidCount = $false
        }
        "wwi_perf.Sale_Heap" = @{
                Count = 2903451490
                Valid = $false
                ValidCount = $false
        }
        "wwi_perf.Sale_Index" = @{
                Count = 2903451490
                Valid = $false
                ValidCount = $false
        }
        "wwi_perf.Sale_Partition01" = @{
                Count = 2903451490
                Valid = $false
                ValidCount = $false
        }
        "wwi_perf.Sale_Partition02" = @{
                Count = 2903451490
                Valid = $false
                ValidCount = $false
        }
        "wwi_security.CustomerInfo" = @{
                Count = 110
                Valid = $false
                ValidCount = $false
        }
        "wwi_security.Sale" = @{
                Count = 52
                Valid = $false
                ValidCount = $false
        }
}

$query = @"
SELECT
        S.name as SchemaName
        ,T.name as TableName
FROM
        sys.tables T
        join sys.schemas S on
                T.schema_id = S.schema_id
"@
$result = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $query


foreach ($dataRow in $result.data) {
        $schemaName = $dataRow[0]
        $tableName = $dataRow[1]

        $fullName = "$($schemaName).$($tableName)"

        if ($tables[$fullName]) {
                
                $tables[$fullName]["Valid"] = $true

                Write-Information "Counting table $($fullName)..."

                try {
                    $countQuery = "select count_big(*) from $($fullName)"
                    $countResult = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $countQuery

                    Write-Information "    Count result $([int64]$countResult[0][0].data[0].Get(0))"

                    if ([int64]$countResult[0][0].data[0].Get(0) -eq $tables[$fullName]["Count"]) {
                            Write-Information "    Records counted is correct."
                            $tables[$fullName]["ValidCount"] = $true
                    }
                    else {
                        Write-Warning "    Records counted is NOT correct."
                        $overallStateIsValid = $false
                    }
                }
                catch { 
                    Write-Warning "    Error while querying table."
                    $overallStateIsValid = $false
                }

        }
}

# $tables contains the current status of the necessary tables

if ($overallStateIsValid -eq $true) {
    Write-Information "Validation Passed"
}
else {
    Write-Warning "Validation Failed - see log output"
}