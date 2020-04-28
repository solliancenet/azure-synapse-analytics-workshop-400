function Create-KeyVault-LinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $Token 
    )

    $keyVaultTemplate = Get-Content -Path "$($TemplatesPath)/keyvault.json"
    $keyVault = $keyVaultTemplate.Replace("#KEY_VAULT_NAME#", $Name)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedservices/$($Name)?api-version=2019-06-01-preview"

    Write-Output $keyVault
    Write-Output $uri

    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $keyVault -Headers @{ Authorization="Bearer $Token" }
 
    Write-Output $result
}

Export-ModuleMember -Function Create-KeyVault-LinkedService