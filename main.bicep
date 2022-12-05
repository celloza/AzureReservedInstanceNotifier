@description('The name for the Reserved Instance Notifier Logic App.')
param logicAppName string

@description('The name for the trigger Logic App.')
param triggerLogicAppName string

@description('A context that will be included in the email notification to identify the customer (usually the customer moniker).')
param contextIdentifier string

@description('A semi-colon seperated list of email addresses to send email notifications to.')
param emailResultsTo string

var mainLogicAppContent = loadJsonContent('ReservedInstanceNotifier.json')
var triggerLogicAppContent = loadJsonContent('ReservedInstanceNotifierTrigger.json')

resource o365connection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'ReservedInstanceNotifierO365Conn'
  location: resourceGroup().location
  properties: {
    api: { 
      id: '${subscription().id}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/office365'
    }
  }
}

resource mainlogicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: resourceGroup().location
  properties: {
    definition: mainLogicAppContent
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    o365connection
  ]
}

resource triggerlogicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: triggerLogicAppName
  location: resourceGroup().location
  properties: {
    definition: triggerLogicAppContent
  }
  dependsOn: [
    mainlogicApp
  ] 
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid('ReservationReaderAssignment', subscription().id, logicAppName)
  scope: tenant()
  properties: {
    roleDefinitionId: '582fc458-8989-419f-a480-75249bc5db7e'
    principalId: mainlogicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
