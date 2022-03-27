
@description('A UNIQUE name')
@maxLength(20)
param appName string = 'iacdemo${uniqueString(resourceGroup().id)}'

@description('The location of the MySQL DB.')
param location string = resourceGroup().location

@description('The MySQL DB Admin Login.')
param administratorLogin string = 'mys_adm'

@secure()
@description('The MySQL DB Admin Password.')
param administratorLoginPassword string

@description('Allow client workstation for local Dev/Test only')
param clientIPAddress string

@description('Allow Azure Spring Cloud from Apps subnet to access MySQL DB')
param startIpAddress string

@description('Allow Azure Spring Cloud from Apps subnet to access MySQL DB')
param endIpAddress string

var serverName = '${appName}'
var databaseSkuName = 'Standard_B1ms' //  'GP_Gen5_2' for single server
var databaseSkuTier = 'Burstable' // 'GeneralPurpose'
var mySqlVersion = '5.7' // https://docs.microsoft.com/en-us/azure/mysql/concepts-supported-versions

/* 
var databaseSkuFamily = 'Gen5'
var databaseSkuSizeMB = 51200
var databaseSkucapacity = 2
resource server 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  location: location
  name: serverName
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
    capacity: databaseSkucapacity
    size: string(databaseSkuSizeMB)
    family: databaseSkuFamily
  }
  properties: {
    createMode: 'Default'
    version: mySqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: databaseSkuSizeMB
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    sslEnforcement: 'Disabled'
  }
}
*/

resource mysqlserver 'Microsoft.DBforMySQL/flexibleServers@2021-05-01' = {
  name: serverName
  location: location
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    // availabilityZone: '1'
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
    highAvailability: {
      mode: 'Disabled'
    }
    replicationRole: 'None'
    version: mySqlVersion
  }
}

output mySQLResourceID string = mysqlserver.id

// Add firewall config to allow Azure Spring Cloud :
// virtualNetworkRules to Allow public access from Azure services 
resource fwRuleAzureSpringCloudApps 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-05-01' = {
  name: 'Allow-Azure-Spring-Cloud-Apps'
  parent: mysqlserver
  properties: {
    startIpAddress: startIpAddress
    endIpAddress: endIpAddress
  }
}

// Allow client workstation with IP 'clientIPAddress' for local Dev/Test only
resource fwRuleClientIPAddress 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-05-01' = {
  name: 'ClientIPAddress'
  parent: mysqlserver
  properties: {
    startIpAddress: clientIPAddress
    endIpAddress: clientIPAddress
  }
}
