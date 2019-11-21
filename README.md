**Build** [![Build Status](https://dev.azure.com/jungodevops/Multiple-CI-Single-CD/_apis/build/status/Terraform-CI?branchName=master)](https://dev.azure.com/jungodevops/Multiple-CI-Single-CD/_build/latest?definitionId=12&branchName=master)

| Stage      | Status                                                                                                                  |
| ---------- | ----------------------------------------------------------------------------------------------------------------------- |
| Dev        | <img src="https://vsrm.dev.azure.com/jungodevops/_apis/public/Release/badge/b453e6a9-9219-4db4-b3fb-5d2a6c4f43df/1/1"/> |
| Test       | <img src=https://vsrm.dev.azure.com/jungodevops/_apis/public/Release/badge/b453e6a9-9219-4db4-b3fb-5d2a6c4f43df/1/3>    |
| Staging    | <img src="https://vsrm.dev.azure.com/jungodevops/_apis/public/Release/badge/b453e6a9-9219-4db4-b3fb-5d2a6c4f43df/1/4"/> |
| Production | <img src="https://vsrm.dev.azure.com/jungodevops/_apis/public/Release/badge/b453e6a9-9219-4db4-b3fb-5d2a6c4f43df/1/5"/> |

# Terraform CI CD Demo

A demo for a complete Terraform CI-CD Process using Azure DevOps Pipelines, deploying infrastructure and application to Azure

- [Terraform CI CD Demo](#terraform-ci-cd-demo)
  - [Connect GitHub and Azure DevOps](#connect-github-and-azure-devops)
  - [Setup Terraform SPN](#setup-terraform-spn)
  - [Connect Azure DevOps to Azure Key Vault](#connect-azure-devops-to-azure-key-vault)
  - [Inner-loop (dev) cycle](#inner-loop-dev-cycle)
    - [Terraform Task Group Template](#terraform-task-group-template)
    - [PR Pipeline](#pr-pipeline)
    - [GitHub Branch Policy](#github-branch-policy)
    - [Dev CI CD](#dev-ci-cd)
  - [Setup Application CI](#setup-application-ci)
  - [Setup Application CD (Delivery)](#setup-application-cd-delivery)
  - [Setup Stack CD (Deployment)](#setup-stack-cd-deployment)
  - [GitHub Tags](#github-tags)

## Connect GitHub and Azure DevOps

- The official documentation from Microsoft can be found [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/repos/github?view=azure-devops&tabs=yaml)
- Other useful documents are [here](https://www.azuredevopslabs.com/labs/azuredevops/github-integration/)
- And I love the Teams integration [here](https://github.com/microsoft/TailwindTraders/tree/master/Documents/DemoScripts/Integrating%20Azure%20DevOps%2C%20Microsoft%20Teams%20and%20GitHub)

## Setup Terraform SPN 

## Connect Azure DevOps to Azure Key Vault

## Inner-loop (dev) cycle

### Terraform Task Group Template

### PR Pipeline

### GitHub Branch Policy

### Dev CI CD

## Setup Application CI

## Setup Application CD (Delivery)

## Setup Stack CD (Deployment)

## GitHub Tags
