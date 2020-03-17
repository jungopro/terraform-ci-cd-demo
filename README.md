# Terraform CI CD Demo

<img src="https://jungoterraform.blob.core.windows.net/demo/phippyandfriends.png" width="400" height="400" alt="PhippyandFriends"/><img src="https://jungoterraform.blob.core.windows.net/demo/Terraform-AzureDevOps-KeyVault.png" width="400" height="400" alt="TerraformCICD"/>

A demo for a complete Terraform CI-CD Process using Azure DevOps Pipelines, deploying infrastructure and application to Azure

- [Terraform CI CD Demo](#terraform-ci-cd-demo)
  - [Current Status](#current-status)
  - [Connect GitHub and Azure DevOps](#connect-github-and-azure-devops)
  - [Setup Terraform SPN, Azure DevOps, Azure Key Vault, Azure Storage](#setup-terraform-spn-azure-devops-azure-key-vault-azure-storage)
  - [Setup Azure Container Registry](#setup-azure-container-registry)
  - [Inner-loop (dev) cycle](#inner-loop-dev-cycle)
    - [Terraform Task Group Template](#terraform-task-group-template)
  - [Setup Terraform PR](#setup-terraform-pr)
    - [PR Pipeline](#pr-pipeline)
    - [Dev CI CD](#dev-ci-cd)
      - [CI](#ci)
      - [CD](#cd)
  - [Setup Application CI](#setup-application-ci)
  - [Setup Stack CD (Deployment)](#setup-stack-cd-deployment)
  - [Environment Promotion](#environment-promotion)
  - [GitHub Tags](#github-tags)

## Current Status

**Build** [![Build Status](https://dev.azure.com/jungodevops/Multiple-CI-Single-CD/_apis/build/status/Terraform-CI?branchName=master)](https://dev.azure.com/jungodevops/Multiple-CI-Single-CD/_build/latest?definitionId=12&branchName=master)

| Stage      | Status                                                                                                                  |
| ---------- | ----------------------------------------------------------------------------------------------------------------------- |
| Dev        | <img src="https://vsrm.dev.azure.com/jungodevops/_apis/public/Release/badge/b453e6a9-9219-4db4-b3fb-5d2a6c4f43df/1/1"/> |
| Test       | <img src=https://vsrm.dev.azure.com/jungodevops/_apis/public/Release/badge/b453e6a9-9219-4db4-b3fb-5d2a6c4f43df/1/3>    |
| Staging    | <img src="https://vsrm.dev.azure.com/jungodevops/_apis/public/Release/badge/b453e6a9-9219-4db4-b3fb-5d2a6c4f43df/1/4"/> |
| Production | <img src="https://vsrm.dev.azure.com/jungodevops/_apis/public/Release/badge/b453e6a9-9219-4db4-b3fb-5d2a6c4f43df/1/5"/> |

## Intro

The purpose of this demo project is to showcase the abilities of Terraform to deploy a complete cloud-native application stack, from the underlying infrastructure to the application itself, using nothing but terraform

The enabler that will connect all the pieces is Azure DevOps. It will:
- Execute the CI of the individual Microservices
- Execute the Terraform Build (Plan) and Deploy (Apply) tasks

We will cover:

- Create the CI process to deploy our infrastrucute to Azure
- Create the CI to build and puse each microservice artifact to ACR
- Create CD to deploy the entire infrastrucute and application to Azure

The Azure DevOps project that showcasing the entire process is publicly available for you to view [here](https://dev.azure.com/jungodevops/Multiple-CI-Single-CD/_dashboards/dashboard/bceea2bf-aab0-4f9e-b52d-7b4906a2bb7f)

## Connect GitHub and Azure DevOps

- The official documentation from Microsoft can be found [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/github?view=azure-devops&tabs=yaml)
- Other useful documents are [here](https://www.azuredevopslabs.com/labs/azuredevops/github-integration/)
- And I love the Teams integration [here](https://github.com/microsoft/TailwindTraders/tree/master/Documents/DemoScripts/Integrating%20Azure%20DevOps%2C%20Microsoft%20Teams%20and%20GitHub)

## Setup Terraform SPN, Azure DevOps, Azure Key Vault, Azure Storage

- This is a prerequisite and will be done manually, before we start with Terraform automation. As this is a one-step step, I didn't bother automating it

[Battle-Tested Terraform Deployment](https://codevalue.com/battle-tested-terraform-deployment/)

## Setup Azure Container Registry

- Create Azure Container Registry and create an admin user. We will store our application artifacts (Docker Images & Helm Charts) there. Save the credentials in the Key Vault created earlier as **repo-name, repo-username & repo-password**. You will need those credentials for the CI / CD process in Azure DevOps

## Inner-loop (dev) cycle

- As a developer, branch out to a feature branch to work on your terraform feature
- Test your code locally on your machine using lint, validate, plan

### Terraform Task Group Template

[A set of tasks that will be used in multiple CI pipelines: Dev CI, Master CI, etc.](./templates/terraform.yml)

## Setup Terraform PR

- Once you tested your code, create a PR from the feature branch to the dev branch
- At this point branch policy kicks-in and tests your merged code with the dev branch using the **pr-pipeline**. If successfull, you can merge your pr
- Read all about how to create policies here [Github Branch protection rules](https://help.github.com/articles/defining-the-mergeability-of-pull-requests/)

### PR Pipeline

- The Azure Pipeline that validates the PR is located [here](./azure-pipelines-pr.yml)
- Make sure to connect the variable group from the Key Vault to your pipeline. Each variable in the key vault you created earlier is used as an input to the pipeline
- Pipeline Steps:
  1. Install Terraform
  2. Initialize Terraform with state stored in Azure Storage
  3. Switch to the Terraform *dev* workspace
  4. Validate Terraform Code
  5. Terraform Dry Run (Plan)

### Dev CI CD

#### CI

- Once the code is merged to dev, a CI-CD process is executed to deploy the changes to the *dev* environment. This is basically our **testing phase**.
- The Azure Pipeline that validates the PR is located [here](./azure-pipelines-dev.yml)
- Pipeline Steps:
  1. Install Terraform
  2. Run the steps in the [template](./templates/terraform.yml)
     1. Initialize Terraform with state stored in Azure Storage
     2. Switch to the Terraform *dev* workspace
     3. Validate Terraform Code
     4. Terraform Dry Run (Plan) with **plan** artifact creation
     5. Publish artifacts to be used in CD

#### CD

- A release is triggered everytime a new artifact is created from the *dev* pipeline
- Release pipeline deploys the terraform plan to Azure and updates the *dev* environment
- I will illustrate the full process to create the CD in the next steps

## Setup Application CI

The application is called "phippy and friends"  
My forked repo is [here](https://github.com/jungopro/phippyandfriends)  
The CI for each microservice is in its **ci-pipeline.yaml** file in the microservice directory:
- [phippy](https://github.com/jungopro/phippyandfriends/blob/master/phippy/ci-pipeline.yml)
- [captainkube](https://github.com/jungopro/phippyandfriends/blob/master/captainkube/ci-pipeline.yml)
- [nodebrady](https://github.com/jungopro/phippyandfriends/blob/master/nodebrady/ci-pipeline.yml)
- [parrot](https://github.com/jungopro/phippyandfriends/blob/master/parrot/ci-pipeline.yml)

The CI for each app will push the app docker image + helm chart into Azure Container Registry  
When you create a new image you should also **manually** bump the chart minor version

## Setup Stack CD (Deployment)

The CD is done via terraform code. You should update the relevant chart version in [terraform.tfvars](./terraform.tfvars) to deploy your desired version of the microservice:

```tf
apps = {
  parrot = {
    version = "v0.3.0"
}
  captainkube = {
    version = "v0.4.0"
  }
  nodebrady = {
    version = "v0.3.0"
  }
  phippy = {
    version = "v0.3.0"
  }
}
```

## Environment Promotion

Once dev is declared **ready**, you should merge dev to master and the code will be pushed to multiple environments:

- dev (again, to verify)
- qa
- stage
- prod

The CI / CD pipeline is the same as the **dev** pipeline, with more environments (dev > qa > stage > prod)

The CD is setup with manual approval between each step so you can verify the changes are as you expect them to be.  
Same code is deployed to all environments

## GitHub Tags

Once code is pushed to master it will create a git tag in github for future refernece. you can download the code for any tag to revert back to a point in time

## Terraform Code Techniques

Below is a list of snippets and exaplanation for different techniques I used in code deployment

```tf
locals {
  tags = merge(var.tags, { "workspace" = "${terraform.workspace}" }) # add terraform workspace tag to any additional tags given as input
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0 # conditional creation
  name     = "${terraform.workspace}-${var.resource_group_name}"
  location = var.resource_group_location

  tags = local.tags
}
```

Usage of the `terraform.workspace` special meta data to create distinc environments from a single code. Also, tag each resource with the meta data for traceability, so you can easily connect actual resource to a terraform workspace

```tf
provider "azurerm" {
  version = "~> 1.2"

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}
```

Configure the provider using explicit variables. This prevents the need to setup Terraform reserved environment variables, such as *ARM_CLIENT_ID* in the build and deploy phase

```tf
provider "kubernetes" {
  version                = "~> 1.8"
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}
```

Configure the kubernetes provider using outputs from the aks resource. This helps creating a dependency and assures that kubernetes-related resoruces will get created after aks-related resources

```tf
provider "helm" {
  debug           = true
  version         = "~> 0.10"
  namespace       = "kube-system"
  service_account = kubernetes_service_account.tiller_sa.metadata.0.name
  install_tiller  = true
  home            = "${abspath(path.root)}/.helm" 

  kubernetes {
    host = azurerm_kubernetes_cluster.aks.kube_config.0.host

    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}
```

Same comment here, for the configuration using aks resource outputs. In addition, the `home = "${abspath(path.root)}/.helm"` is used since we run the CI and CD in seperatation, using the `-out plan.file`. This is a [known bug](https://github.com/terraform-providers/terraform-provider-helm/issues/335).

```tf
main.tf

locals {
  parrot_values = {
    "ingress.basedomain" = azurerm_kubernetes_cluster.aks.addon_profile.0.http_application_routing[0].http_application_routing_zone_name
  }
}

resource "helm_release" "phippyandfriends" {
  for_each   = var.apps
  name       = each.key
  repository = data.helm_repository.repo.metadata[0].name
  chart      = each.key
  namespace  = kubernetes_namespace.phippyandfriends.metadata.0.name
  version    = lookup(each.value, "version") != "" ? lookup(each.value, "version") : null

  set {
    name  = "image.repository"
    value = "${var.repo_name}.azurecr.io/${each.key}"
  }

  dynamic "set" {
    for_each = local.parrot_values
    content {
      name  = each.key == "parrot" ? set.key : ""
      value = each.key == "parrot" ? set.value : ""
    }
  }

  depends_on = [
    kubernetes_cluster_role_binding.tiller_sa_cluster_admin_rb,
    kubernetes_service_account.tiller_sa,
    kubernetes_cluster_role_binding.default_view
  ]
}
...
variables.tf

variable "apps" {
  type = map(object({
    version = string
  }))
  default = {}
}
...
terraform.tfvars
apps = {
  parrot = {
    version = "v0.3.0"
  }
  captainkube = {
    version = "v0.4.0"
  }
  nodebrady = {
    version = "v0.3.0"
  }
  phippy = {
    version = "v0.3.0"
  }
}
```

An example of the **for_each** and **dynamic**, new in Terraform 0.12.x. I really like defining a map of objects variable and grab the inputs from there. Also, when setting values for the helm chart (using the `dynamic "set"` block) I added a conditional addition just for a specific microservice called **parrot***
