@allowed([
  'Owner'
  'Contributor'
  'NetworkContributor'
  'Reader'
])

@description('VNet Built-in role to assign')
param networkRoleType string

@description('The Azure Spring Cloud Resource Provider ID')
param azureSpringCloudRp string


// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var role = {
  Owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
  NetworkContributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
  AcrPull: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
  KeyVaultAdministrator: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483'
  KeyVaultReader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/21090545-7ca7-4776-b22c-e363652d74d2'
  KeyVaultSecretsUser: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'
}

// https://docs.microsoft.com/en-us/azure/spring-cloud/quickstart-deploy-infrastructure-vnet-azure-cli#prerequisites
// The Azure Spring Cloud Resource Provider requires Owner permission to your virtual network in order to grant a dedicated and dynamic service principal on the virtual network for further deployment and maintenance
resource AzureSpringCloudRpRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(networkRoleType , azureSpringCloudRp)
  scope: vnet
  properties: {
    roleDefinitionId: role[networkRoleType] // subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: azureSpringCloudRp
    principalType: 'ServicePrincipal'
  }
}
