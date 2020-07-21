# Environment setup instructions

## Pre-requisites

* Windows PowerShell
* Azure PowerShell

    ```powershell
    if (Get-Module -Name AzureRM -ListAvailable) {
        Write-Warning -Message 'Az module not installed. Having both the AzureRM and Az modules installed at the same time is not supported.'
    } else {
        Install-Module -Name Az -AllowClobber -Scope CurrentUser
    }
    ```

* `Az.CosmosDB` 0.1.4 cmdlet

    ```powershell
    Install-Module -Name Az.CosmosDB -RequiredVersion 0.1.4
    ```

* `sqlserver` module

    ```powershell
    Install-Module -Name SqlServer
    ```

* Install VC Redist: <https://aka.ms/vs/15/release/vc_redist.x64.exe>
* Install MS ODBC Driver 17 for SQL Server: <https://www.microsoft.com/download/confirmation.aspx?id=56567>
* Install SQL CMD x64: <https://go.microsoft.com/fwlink/?linkid=2082790>
* Install Microsoft Online Services Sign-In Assistant for IT Professionals RTW: <https://www.microsoft.com/download/details.aspx?id=41950>

Create the following file: **C:\LabFiles\AzureCreds.ps1**

```powershell
$AzureUserName="odl_user_NNNNNN@msazurelabs.onmicrosoft.com"
$AzurePassword="..."
$TokenGeneratorClientId="1950a258-227b-4e31-a9cf-717495945fc2"
$AzureSQLPassword="..."
```

> The `AzureSQLPassword` value is the value passed to the `sqlAdministratorLoginPassword` parameter when running the `01-asa-workspace-core.json` ARM template. You can find this value by looking at the `SQL-USER_ASA` Key Vault secret.

## Run the ARM Template

* Run the 00-asa-workspace-core.json template, it will take ~30 minutes to complete

## Execute setup scripts

* Open PowerShell as an Administrator and change directories to the root of this repo within your local file system.
* Run `Set-ExecutionPolicy Unrestricted`.
* Execute `Connect-AzAccount` and sign in to the ODL user account when prompted.
* Execute `.\artifacts\environment-setup\automation\01-environment-setup.ps1`.
* Execute `.\artifacts\environment-setup\automation\03-environment-validate.ps1`.

## Path #2 (Cloud Shell)

The above script will setup the environment when using a local PowerShell environment. You can execute the following path using the Azure Cloud Shell:

* Deploy the ARM template
* Open the Cloud Shell, execute the following:

```PowerShell
git clone https://github.com/solliancenet/azure-synapse-analytics-workshop-400.git synapse-ws-L400
```

```cli
az login
```

```PowerShell
cd './synapse-ws-L400/artifacts/environment-setup/automation'
```

* Execute the **01-environment-setup.ps1** script by executing the following command:

```PowerShell
./01-environment-setup.ps1
./03-environment-validate.ps1
```

## Steps & Timing

The entire script will take a little over an hour to complete.  Major steps include:

* Configure Synapase resources
* Download all data sets and files into the data lake (~15 mins)
* Execute the setup and execute the SQL pipeline (~30 mins)
* Execute the Cosmos DB pipeline (~25 mins)
