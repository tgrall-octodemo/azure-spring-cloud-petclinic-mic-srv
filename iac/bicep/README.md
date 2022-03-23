# Azure Spring Cloud

TODO : Use [Pipelines with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions?tabs=CLI)
```sh

# The one below returns 0 ID because of Tenant mismatch
tenantId=$(az account show --query tenantId -o tsv)
azureSpringCloudObjectId="$(az ad sp list --filter "displayname eq 'Azure Spring Cloud Resource Provider'" --query "[?appDisplayName=='Azure Spring Cloud Resource Provider']" --query "[?appOwnerTenantId=='$tenantId'].objectId" -o tsv | head -1)"

# This query returns 1 and only 1 Id: d2531223-68f9-459e-b225-5592f90d145e
azureSpringCloudRpObjectId="$(az ad sp list --filter "displayname eq 'Azure Spring Cloud Resource Provider'" --query "[?appDisplayName=='Azure Spring Cloud Resource Provider'].objectId" -o tsv | head -1)"

az ad sp list --filter "displayname eq 'Azure Spring Cloud Resource Provider'" --query "[?appDisplayName=='Azure Spring Cloud Resource Provider'].objectId" -o tsv |
while IFS= read -r line
do
    echo "$line" &
done

# This query returns 1 and only 1 Id: e8de9221-a19c-4c81-b814-fd37c6caf9d2
azureSpringCloudRpAppId="$(az ad sp list --filter "displayname eq 'Azure Spring Cloud Resource Provider'" --query "[?appDisplayName=='Azure Spring Cloud Resource Provider'].appId" -o tsv | head -1)"

# Check, choose a Region with AZ : https://docs.microsoft.com/en-us/azure/availability-zones/az-overview#azure-regions-with-availability-zones
az group create --name rg-iac-kv --location northeurope
az group create --name rg-iac-asc-petclinic-mic-srv --location northeurope

az deployment group create --name iac-101-kv -f ./kv/kv.bicep -g rg-iac-kv \
    --parameters @./kv/parameters-kv.json

az deployment group create --name iac-101-asc -f ./asc/main.bicep -g rg-iac-asc-petclinic-mic-srv \
    --parameters @./asc/parameters.json --debug # --what-if to test like a dry-run
```

Note: you can Run a Bicep script to debug and output the results to Azure Storage, see the [doc](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep#sample-bicep-files)