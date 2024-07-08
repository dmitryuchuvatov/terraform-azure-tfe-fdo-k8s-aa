# Terraform Enterprise Flexible Deployment Options - Active-Active mode on Kubernetes (AKS/Azure)

# Diagram

WIP

# Prerequisites

+ Have Terraform installed as per the [official documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

+ Have **Azure CLI** installed as per the [official documentation](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

+ Microsoft Azure account

+ AWS account

* Have **kubectl** installed as per the [official documentation](https://kubernetes.io/docs/tasks/tools/)

* Have **helm** installed as per the [official documentation](https://helm.sh/docs/intro/install/)

+ TFE FDO license

# How To

## Clone repository

```
git clone https://github.com/dmitryuchuvatov/terraform-azure-tfe-fdo-k8s-aa.git
```

## Change folder

```
cd terraform-azure-tfe-fdo-k8s-aa
```

## Rename the file called `terraform.tfvars-sample` to `terraform.tfvars` and replace the values with your own.
The current content is below:

```
environment_name    = "dmitry-fdo-aks"    # Name of the environment, used in naming of resources
region              = "West Europe"       # Azure region to deploy in
vnet_cidr           = "10.200.0.0/16"     # The IP range for the VNet in CIDR format default
postgresql_user     = "postgres"          # Name of PostgreSQL user
postgresql_password = "Password1#"        # Password for PostgreSQL account
storage_name        = "tfestorageaccount" # Name used to create storage account. Can contain ONLY lowercase letters and numbers; must be unique across all existing storage account names in Azure                                                                                        
```

## Authenticate to Azure

Run the command below without any parameters and follow the instructions to sign in to Azure.

```
az login
```

Alternatively, utilize [this document](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/guides/azure_cli) to authenticate


## Terraform init

```
terraform init
```

## Terraform apply

```
terraform apply
```

When prompted, type **yes** and hit **Enter** to start provisioning Azure infrastructure.

You should see the similar result:

```
Apply complete! Resources: 27 added, 0 changed, 0 destroyed.

Outputs:

cluster_name = "dmitry-fdo-aks"
container_name = "dmitry-fdo-aks-container"
kubectl_config = "az aks get-credentials --resource-group dmitry-fdo-aks-resources --name dmitry-fdo-aks --overwrite-existing"
pg_address = "dmitry-fdo-aks-postgres.postgres.database.azure.com"
pg_dbname = "tfe"
pg_password = <sensitive>
pg_user = "postgres"
prefix = "dmitry-fdo-aks"
redis_host = "dmitry-fdo-aks-redis.redis.cache.windows.net"
redis_primary_access_key = <sensitive>
resource_group = "dmitry-fdo-aks-resources"
storage_account = "tfestorageaccount"
storage_account_key = <sensitive>
```
