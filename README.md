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

## Switch to `tfe` folder

```
cd tfe/
```

## Rename the file called `terraform.tfvars-sample` to `terraform.tfvars` and replace the values with your own.
The current content is below:

```
route53_zone            = "tf-support.hashicorpdemo.com"   # The domain of your hosted zone in Route 53
route53_subdomain       = "dmitry-fdo-aks"                        # The subomain of the URL
cert_email              = "dmitry.uchuvatov@hashicorp.com" # The email address used to register the certificate
region                  = "eu-west-1"                      # AWS region to deploy in
tfe_encryption_password = "Password1#"                     # TFE encryption password
tfe_release             = "v202406-1"                      # Which release version of TFE to install
tfe_license             = "02MV4UU43..."                   # Value from the License file
replica_count           = "1"                              # Number of Pods/replicas                                                                                                            
```

## Set AWS credentials

```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
```

## Terraform initialize

```
terraform init
```

## Terraform apply

```
terraform apply
```

When prompted, type **yes** and hit **Enter** to start installing TFE.

After some time, you should see the similar result:

```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

tfe_url = "https://dmitry-fdo-aks.tf-support.hashicorpdemo.com"
```

## Next steps

[Provision your first administrative user](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/initial-admin-user) and start using Terraform Enterprise.
