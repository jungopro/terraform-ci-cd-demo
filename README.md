# Terraform CI CD Demo

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
