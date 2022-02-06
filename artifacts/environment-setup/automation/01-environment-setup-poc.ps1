$InformationPreference = "Continue"

$lines = Get-content c:\temp\Synapse\usernames10.txt;

if(Get-Module -Name solliance-synapse-automation){
        Remove-Module solliance-synapse-automation
}

Import-Module "..\solliance-synapse-automation"


foreach($line in $lines)
{
    $vals = $line.split("`t")
    $username = $vals[0];
    $password = $vals[1];

    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

    Connect-AzAccount -Credential $cred | Out-Null

    $resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*-L400*" }).ResourceGroupName

    if ($resourceGroupName.Count -gt 1)
    {
            $resourceGroupName = $resourceGroupName[0];
    }

    Write-Information "Running on $resourceGroupName";

    $artifactsPath = "..\..\"
    $reportsPath = "..\reports"
    $templatesPath = "..\templates"
    $datasetsPath = "..\datasets"
    $dataflowsPath = "..\dataflows"
    $pipelinesPath = "..\pipelines"
    $sqlScriptsPath = "..\sql"

    Write-Information "Using $resourceGroupName";

    $uniqueId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]
    $subscriptionId = (Get-AzContext).Subscription.Id
    $tenantId = (Get-AzContext).Tenant.Id
    $global:logindomain = (Get-AzContext).Tenant.Id;

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
    $amlWorkspaceName = "asaamlworkspace$($uniqueId)"
    $global:sqlEndpoint = "$($workspaceName).sql.azuresynapse.net"
    $global:sqlUser = "asa.sql.admin"

    Write-Information "Copy Public Data"

    Ensure-ValidTokens

    if ([System.Environment]::OSVersion.Platform -eq "Unix")
    {
            $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-linux"

            if (!$azCopyLink)
            {
                    $azCopyLink = "https://azcopyvnext.azureedge.net/release20200709/azcopy_linux_amd64_10.5.0.tar.gz"
            }

            Invoke-WebRequest $azCopyLink -OutFile "azCopy.tar.gz"
            tar -xf "azCopy.tar.gz"
            $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy).Directory.FullName
            cd $azCopyCommand
            chmod +x azcopy
            cd ..
            $azCopyCommand += "\azcopy"
    }
    else
    {
            $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-windows"

            if (!$azCopyLink)
            {
                    $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
            }

            Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
            Expand-Archive "azCopy.zip" -DestinationPath ".\" -Force
            $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy.exe).Directory.FullName
            $azCopyCommand += "\azcopy"
    }

    #$jobs = $(azcopy jobs list)

    $download = $true;

    $publicDataUrl = "https://solliancepublicdata.blob.core.windows.net/"
    $dataLakeStorageUrl = "https://"+ $dataLakeAccountName + ".dfs.core.windows.net/"
    $dataLakeStorageBlobUrl = "https://"+ $dataLakeAccountName + ".blob.core.windows.net/"
    $dataLakeStorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $dataLakeAccountName)[0].Value
    $dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $dataLakeStorageAccountKey
    $destinationSasKey = New-AzStorageContainerSASToken -Container "wwi-02" -Context $dataLakeContext -Permission rwdl

    if ($download)
    {
            Write-Information "Copying sample sales raw data directories from the public data account..."

            $dataDirectories = @{
                    salespoc = "wwi-02,wwi-02/sale-poc/"
            }

            foreach ($dataDirectory in $dataDirectories.Keys) {

                    $vals = $dataDirectories[$dataDirectory].tostring().split(",");

                    $source = $publicDataUrl + $vals[1];

                    $path = $vals[0];

                    $destination = $dataLakeStorageBlobUrl + $path + $destinationSasKey
                    Write-Information "Copying directory $($source) to $($destination)"
                    & $azCopyCommand copy $source $destination --recursive=true
            }
    }
}