param prefix string
param linuxContainerName string
param windowsContainerName string
param secretValue string
param allowedRemoteIpAddress string
param adminUserObjectId string

var keyVaultName = '${prefix}-kv'
var vnetName = '${prefix}-vnet'
var storageAccountName = 'stor${uniqueString(resourceGroup().id)}'
var linuxAspName = '${prefix}-linux-asp'
var windowsAspName = '${prefix}-windows-asp'
var windowsContainerAppName = '${prefix}-windows-container-app'
var linuxContainerAppName = '${prefix}-linux-container-app'

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.3.0.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'windows-asp-subnet'
        properties: {
          addressPrefix: '10.3.1.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
              locations: [
                '*'
              ]
            }
          ]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'linux-asp-subnet'
        properties: {
          addressPrefix: '10.3.2.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
              locations: [
                '*'
              ]
            }
          ]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource windowsAsp 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: windowsAspName
  location: resourceGroup().location
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
    size: 'P1v3'
    family: 'Pv3'
    capacity: 1
  }
  kind: 'windows'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: true
    hyperV: true
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

resource linuxAsp 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: linuxAspName
  location: resourceGroup().location
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
    size: 'P1v3'
    family: 'Pv3'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: keyVault
  name: 'mysecret'
  properties: {
    value: secretValue
    attributes: {
      enabled: true
    }
  }
}

resource defaultSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vnet
  name: 'default'
  properties: {
    addressPrefix: '10.3.0.0/24'
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource linuxAspIntegrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vnet
  name: 'linux-asp-subnet'
  properties: {
    addressPrefix: '10.3.2.0/24'
    serviceEndpoints: [
      {
        service: 'Microsoft.KeyVault'
        locations: [
          '*'
        ]
      }
    ]
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource windowsAspIntegrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vnet
  name: 'windows-asp-subnet'
  properties: {
    addressPrefix: '10.3.1.0/24'
    serviceEndpoints: [
      {
        service: 'Microsoft.KeyVault'
        locations: [
          '*'
        ]
      }
    ]
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource linuxContainerAppConfig 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: linuxContainerApp
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: 'DOCKER|${linuxContainerName}'
    vnetName: linuxContainerAppVnetCxn.name
    vnetRouteAllEnabled: true
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    appSettings: [
      {
        name: 'APP_SECRET'
        value: '@Microsoft.KeyVault(SecretUri=${keyVaultSecret.properties.secretUri})'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
  }
}

resource windowsContainerAppConfig 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: windowsContainerApp
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    windowsFxVersion: 'DOCKER|${windowsContainerName}'
    vnetName: windowsContainerAppVnetCxn.name
    vnetRouteAllEnabled: true
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    appSettings: [
      {
        name: 'APP_SECRET'
        value: '@Microsoft.KeyVault(SecretUri=${keyVaultSecret.properties.secretUri})'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          value: allowedRemoteIpAddress
        }
      ]
      virtualNetworkRules: [
        {
          id: linuxAspIntegrationSubnet.id
          ignoreMissingVnetServiceEndpoint: false
        }
        {
          id: windowsAspIntegrationSubnet.id
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: windowsContainerApp.identity.principalId
        permissions: {
          keys: []
          secrets: [
            'get'
            'list'
          ]
          certificates: []
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: linuxContainerApp.identity.principalId
        permissions: {
          keys: []
          secrets: [
            'get'
            'list'
          ]
          certificates: []
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: adminUserObjectId
        permissions: {
          keys: [
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          certificates: [
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
            'managecontacts'
            'manageissuers'
            'getissuers'
            'listissuers'
            'setissuers'
            'deleteissuers'
          ]
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
    vaultUri: 'https://${keyVaultName}.vault.azure.net/'
    provisioningState: 'Succeeded'
  }
}

resource linuxContainerApp 'Microsoft.Web/sites@2021-01-15' = {
  name: linuxContainerAppName
  location: resourceGroup().location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: linuxAsp.id
    reserved: true
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'DOCKER|${linuxContainerName}'
      alwaysOn: true
    }
    virtualNetworkSubnetId: linuxAspIntegrationSubnet.id
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource windowsContainerApp 'Microsoft.Web/sites@2021-01-15' = {
  name: windowsContainerAppName
  location: resourceGroup().location
  kind: 'app,container,windows'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: windowsAsp.id
    reserved: false
    isXenon: true
    hyperV: true
    siteConfig: {
      numberOfWorkers: 1
      windowsFxVersion: 'DOCKER|belstarr/go-web-kv-env-windows:0.2.0'
      alwaysOn: true
    }
    virtualNetworkSubnetId: windowsAspIntegrationSubnet.id
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource linuxContainerAppVnetCxn 'Microsoft.Web/sites/virtualNetworkConnections@2021-01-15' = {
  parent: linuxContainerApp
  name: 'linux-asp-vnet-cxn'
  properties: {
    vnetResourceId: linuxAspIntegrationSubnet.id
    isSwift: true
  }
}

resource windowsContainerAppVnetCxn 'Microsoft.Web/sites/virtualNetworkConnections@2021-01-15' = {
  parent: windowsContainerApp
  name: 'windows-asp-subnet-cxn'
  properties: {
    vnetResourceId: windowsAspIntegrationSubnet.id
    isSwift: true
  }
}
