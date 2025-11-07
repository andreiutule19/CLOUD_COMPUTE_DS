targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param resourceGroupName string = ''
param apiAppServiceName string = ''
param frontendAppServiceName string = ''
param appServicePlanName string = ''

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Name of the service defined in azure.yaml
// A tag named azd-service-name with this value should be applied to the service host resource, such as:
//   Microsoft.Web/sites for appservice, function
// Example usage:
//   tags: union(tags, { 'azd-service-name': apiServiceName })

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Add resources to be provisioned below.

// FastAPI backend App Service
module api './core/host/appservice.bicep' = {
  name: 'api'
  scope: rg
  params: {
    name: !empty(apiAppServiceName) ? apiAppServiceName : '${abbrs.webSitesAppService}api-${resourceToken}'
    location: location
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.12'
    appCommandLine: 'gunicorn -w 2 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000 app.main:app'
    scmDoBuildDuringDeployment: true
    tags: union(tags, { 'azd-service-name': 'api' })
  }
}

// Streamlit frontend App Service
module frontend './core/host/appservice.bicep' = {
  name: 'frontend'
  scope: rg
  params: {
    name: !empty(frontendAppServiceName) ? frontendAppServiceName : '${abbrs.webSitesAppService}frontend-${resourceToken}'
    location: location
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.12'
    appCommandLine: 'python -m streamlit run app.py --server.port 8000 --server.address 0.0.0.0'
    scmDoBuildDuringDeployment: true
    tags: union(tags, { 'azd-service-name': 'frontend' })
    appSettings: {
      BACKEND_URL: api.outputs.uri
      STREAMLIT_SERVER_PORT: '8000'
      STREAMLIT_SERVER_ENABLECORS: 'false'
      STREAMLIT_SERVER_HEADLESS: 'true'
    }
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'B1'
    }
  }
}

// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output API_BASE_URL string = api.outputs.uri
output FRONTEND_BASE_URL string = frontend.outputs.uri

