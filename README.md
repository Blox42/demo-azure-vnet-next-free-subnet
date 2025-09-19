# Azure VNET with Infoblox IPAM - Terraform Demo

Automated Azure Virtual Network provisioning with Infoblox IPAM integration, deployed via Semaphore CI/CD.

## Overview

This project demonstrates:
- **Dynamic IP Allocation** from Infoblox address blocks
- **Azure VNET/Subnet Creation** with allocated CIDR ranges  
- **Infrastructure IP Reservation** (.1, .2, .3 for Azure services)
- **Bi-directional Sync** between Azure and Infoblox
- **Automated CI/CD** via Semaphore pipelines

```
Semaphore CI/CD ──▶ Infoblox IPAM ──▶ Azure VNETs & Subnets
```

## Semaphore CI/CD Setup

**Prerequisites:** Semaphore instance (`https://semaphore.infra.blox42.rocks/`), Azure Service Principal, Infoblox CSP API access

### 1. Project Setup
1. **Import Repository**: Semaphore UI → Projects → Add New Project → GitHub → `https://github.com/Blox42/demo-azure-vnet-next-free-subnet`
2. **Configure Secrets** (Key Store):
   ```yaml
   azure-credentials:
     AZURE_SUBSCRIPTION_ID: "<subscription-id>"
   infoblox-credentials:
     INFOBLOX_CSP_URL: "https://csp.eu.infoblox.com"
     INFOBLOX_API_KEY: "<api-key>"
   ```
3. **Set Variables** (Optional - defaults in code):
   ```yaml
   TF_VAR_region: "West Europe"
   TF_VAR_resource_group: "blox42-rg"
   TF_VAR_vnet_prefix: "blox42-demo"
   ```

### 2. Pipeline Workflows

**Automatic (on push to main):** `Plan → Manual Approval → Apply`  
**Manual Destroy:** Available via Promotions → "Manual Destroy"

### 3. Usage
1. **Deploy**: Push changes to `main` → Review plan → Approve apply
2. **Destroy**: Semaphore UI → Promotions → Manual Destroy

## Local Development & Configuration

**For local testing**, create `terraform.auto.tfvars`:
```hcl
subscription_id = "your-azure-subscription-id"
csp_url = "https://csp.eu.infoblox.com"
api_key = "your-infoblox-api-key"
region = "West Europe"
resource_group = "blox42-rg"
vnets = ["vnet1", "vnet2", "vnet3"]
```

**Key Variables:**
- **Azure**: `subscription_id`, `region`, `resource_group`
- **Infoblox**: `csp_url`, `api_key`, `infoblox_address_block_name`
- **Deployment**: `vnet_prefix`, `vnets[]`, `subnet_cidr`, `subnet_tags{}`

## Troubleshooting

**Common Issues:**
- **Azure Auth**: Verify `AZURE_SUBSCRIPTION_ID` in Key Store, check Service Principal permissions
- **Infoblox API**: Validate `INFOBLOX_CSP_URL`/`API_KEY`, confirm Address Block exists
- **Pipeline**: Check Semaphore logs, verify secrets configuration
- **State Conflicts**: Use destroy pipeline for cleanup

**Debug Commands:**
```bash
terraform validate                    # Check syntax
terraform state list                  # Show resources
TF_LOG=DEBUG terraform plan          # Detailed logging
```

## Security & Support

**Security:** Secrets in Semaphore Key Store, RBAC access control, audit logging, protected `main` branch, manual approval required

**Support:** Check Semaphore logs → Review Terraform errors → Verify connectivity → Contact infrastructure team
