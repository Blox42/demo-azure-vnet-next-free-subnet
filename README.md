# Azure VNET with Infoblox IPAM - Terraform Demo

A demonstration project showcasing automated Azure Virtual Network provisioning with Infoblox IPAM integration, deployed via Semaphore CI/CD.

## What it does

- **Dynamic IP Allocation**: Automatically allocates next available subnets from Infoblox address blocks
- **Azure Integration**: Creates Azure Virtual Networks and subnets with allocated CIDR ranges
- **IP Reservation**: Reserves critical IP addresses (.1, .2, .3) for Azure infrastructure
- **Bi-directional Sync**: Synchronizes subnet information between Azure and Infoblox
- **CI/CD Automation**: Fully automated deployment via Semaphore CI/CD pipelines

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Semaphore     │    │   Infoblox      │    │     Azure       │
│     CI/CD       │────▶│     IPAM        │────▶│     VNETs       │
│                 │    │                 │    │   & Subnets     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Semaphore CI/CD Setup

### 1. Prerequisites

- Access to Semaphore instance: `https://semaphore.infra.blox42.rocks/`
- API Key: `s9ooyxaoapw2x5imwa2n9deqkkck_p9zcbml4livsim=`
- Azure Service Principal with appropriate permissions
- Infoblox CSP account with API access

### 2. Repository Configuration

**a. Link GitHub Repository**
1. Log in to Semaphore UI
2. Navigate to Projects → Add New Project
3. Select GitHub integration
4. Import repository: `https://github.com/Blox42/demo-azure-vnet-next-free-subnet`

**b. Configure Secrets (Key Store)**

Go to Project → Configuration → Key Store and add:

```yaml
Secrets:
  azure-credentials:
    - AZURE_SUBSCRIPTION_ID: "<your-azure-subscription-id>"
    
  infoblox-credentials:
    - INFOBLOX_CSP_URL: "https://csp.eu.infoblox.com"
    - INFOBLOX_API_KEY: "<your-infoblox-api-key>"
```

**c. Configure Variables (Optional)**

Create Variable Group `azure-vnet-config` with:
```yaml
Variables:
  TF_VAR_region: "West Europe"
  TF_VAR_resource_group: "blox42-rg"
  TF_VAR_infoblox_address_block_name: "Azure VNET Address Block"
  TF_VAR_vnet_prefix: "blox42-demo"
  TF_VAR_subnet_cidr: "24"
  TF_VAR_subnet_comment: "Managed by Semaphore CI/CD"
```

### 3. Pipeline Workflow

#### Automatic Pipeline (on push to main)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Terraform Plan  │────▶│ Manual Approval │────▶│ Terraform Apply │
│   (automatic)   │    │   (if needed)   │    │   (on approval) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### Manual Destroy Pipeline
```
┌─────────────────┐
│ Terraform       │
│ Destroy         │
│ (manual only)   │
└─────────────────┘
```

### 4. Pipeline Configuration Files

- **`.semaphore/semaphore.yml`**: Main pipeline with plan/apply workflow
- **`.semaphore/destroy.yml`**: Destroy pipeline (manual execution only)

### 5. Usage Workflow

#### Standard Deployment
1. **Push Changes**: Push Terraform changes to `main` branch
2. **Auto Plan**: Semaphore automatically runs `terraform plan`
3. **Review Plan**: Review the generated plan in Semaphore UI
4. **Manual Apply**: Manually trigger apply if plan looks good
5. **Monitor**: Watch deployment progress in Semaphore

#### Emergency Cleanup
1. **Navigate to Promotions**: Go to project → Promotions
2. **Trigger Destroy**: Manually start "Manual Destroy" promotion
3. **Confirm**: Verify destroy completes successfully

### 6. Local Development (Optional)

For local testing, create `terraform.auto.tfvars` (excluded by .gitignore):

```hcl
# Azure Configuration
subscription_id = "your-azure-subscription-id"

# Infoblox Configuration
csp_url = "https://csp.eu.infoblox.com"
api_key = "your-infoblox-api-key"

# Deployment Configuration
region = "West Europe"
resource_group = "blox42-rg"
infoblox_address_block_name = "Azure VNET Address Block"
vnet_prefix = "blox42-demo"
vnets = ["vnet1", "vnet2", "vnet3", "vnet4", "vnet5"]
subnet_cidr = "24"
subnet_comment = "Local development test"
subnet_tags = {
  owner   = "local-dev"
  managed = "terraform"
  usage   = "vnet"
}
```

Then run:
```bash
terraform init
terraform plan
terraform apply
```

## Configuration Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `subscription_id` | Azure Subscription ID | `12345678-1234-1234-1234-123456789abc` |
| `csp_url` | Infoblox CSP URL | `https://csp.eu.infoblox.com` |
| `api_key` | Infoblox API Key | `<api-key>` |
| `region` | Azure Region | `West Europe` |
| `resource_group` | Azure Resource Group | `blox42-rg` |
| `infoblox_address_block_name` | Infoblox Address Block | `Azure VNET Address Block` |
| `vnet_prefix` | VNET Naming Prefix | `blox42-demo` |
| `vnets` | List of VNET Names | `["vnet1", "vnet2"]` |
| `subnet_cidr` | Subnet Size (CIDR) | `24` |
| `subnet_comment` | Description | `Created by Terraform` |
| `subnet_tags` | Resource Tags | `{"owner": "team"}` |

## Troubleshooting

### Common Issues

**1. Azure Authentication Failed**
- Verify `AZURE_SUBSCRIPTION_ID` is correct in Key Store
- Check Azure Service Principal permissions
- Ensure Resource Group exists

**2. Infoblox API Errors**
- Validate `INFOBLOX_CSP_URL` and `INFOBLOX_API_KEY`
- Confirm Address Block exists in Infoblox
- Check network connectivity to CSP

**3. Terraform State Issues**
- Semaphore manages state automatically
- For state conflicts, check concurrent runs
- Use destroy pipeline for cleanup

**4. Pipeline Failures**
- Check Semaphore logs for detailed error messages
- Verify all secrets are properly configured
- Ensure GitHub integration is working

### Debug Commands

For local debugging:
```bash
# Validate configuration
terraform validate

# Check current state
terraform state list

# Plan with detailed logging
TF_LOG=DEBUG terraform plan

# Show current configuration
terraform show
```

## Security Considerations

- **Secrets Management**: All sensitive data stored in Semaphore Key Store
- **Access Control**: Use Semaphore RBAC for pipeline access
- **Audit Trail**: All deployments logged in Semaphore
- **Branch Protection**: Only deploy from protected `main` branch
- **Manual Approval**: Apply operations require manual confirmation

## Support

For issues or questions:
1. Check Semaphore pipeline logs
2. Review Terraform error messages
3. Verify Azure/Infoblox connectivity
4. Contact infrastructure team if needed
