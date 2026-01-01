data "azuredevops_project" "main" {
  name = "serverless-cart"
}

resource "azuredevops_serviceendpoint_azurerm" "azure_connection" {
  project_id            = data.azuredevops_project.main.id
  service_endpoint_name = "MyAzureServiceConnection"
  description           = "Managed by Terraform"

  # This uses the same credentials as your current azurerm provider
  azurerm_spn_tenantid      = var.TENANT_ID
  azurerm_subscription_id   = var.SUBSCRIPTION
  azurerm_subscription_name = var.SUBSCRIPTION_NAME
}

resource "azuredevops_serviceendpoint_github" "gh_connection" {
  project_id = data.azuredevops_project.main.id
  service_endpoint_name = "GitHub-Repo-Connection"

  auth_personal {
    personal_access_token = var.GITHUB_PAT
  }
}

resource "azuredevops_build_definition" "deploy_pipeline" {
  project_id = data.azuredevops_project.main.id
  name       = "Cart-Function-Deploy"
  path       = "\\"

  repository {
    repo_type   = "GitHub"
    repo_id     = "ravi1983/serverless-api-ref-arch"
    branch_name = "refs/heads/master"
    yml_path    = "opentofu/azure/azure_devops/azure-pipelines.yml"

    service_connection_id = azuredevops_serviceendpoint_github.gh_connection.id
  }

  ci_trigger {
    use_yaml = true
  }
}

resource "azuredevops_pipeline_authorization" "auth_azure" {
  project_id = data.azuredevops_project.main.id
  resource_id = azuredevops_serviceendpoint_azurerm.azure_connection.id
  type = "endpoint"
  pipeline_id = azuredevops_build_definition.deploy_pipeline.id
}

resource "azuredevops_pipeline_authorization" "auth_github" {
  project_id = data.azuredevops_project.main.id
  resource_id = azuredevops_serviceendpoint_github.gh_connection.id
  type = "endpoint"
  pipeline_id = azuredevops_build_definition.deploy_pipeline.id
}