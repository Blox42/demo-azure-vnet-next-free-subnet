# Infoblox Terraform Provider Demo - Azure

A demo showcasing how to use the Infoblox Terraform provider to automatically provision Azure Virtual Networks and subnets with dynamic IP address management.

## What it does

- Allocates next available subnets from Infoblox address blocks
- Creates Azure Virtual Networks and subnets with the allocated CIDR ranges
- Reserves critical IP addresses (.1, .2, .3) for Azure infrastructure
- Synchronizes subnet information between Azure and Infoblox

## Quick Setup

1. **Prerequisites**
   - Terraform >= 1.0
   - Azure CLI configured
   - Infoblox CSP account and API key

2. **Configure credentials**
   ```bash
   cat > terraform.auto.tfvars << EOF
   csp_url = "https://csp.eu.infoblox.com"
   api_key = "your-infoblox-api-key"
   subscription_id = "your-azure-subscription-id"
   EOF
   ```

3. **Customize settings**
   ```bash
   # Edit terraform.tfvars with your configuration
   nano terraform.tfvars
   ```

4. **Deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration

Key variables in `terraform.tfvars`:
- `region`: Azure region (e.g., "westeurope")
- `resource_group`: Azure Resource Group name
- `infoblox_address_block_name`: Name of your Infoblox address block
- `vnets`: List of Virtual Network names to create
- `subnet_cidr`: Subnet size (e.g., "24")

## Cleanup

```bash
terraform destroy
```

## Security Note

Never commit `terraform.auto.tfvars` to version control. Add it to `.gitignore`:
```bash
echo "terraform.auto.tfvars" >> .gitignore
``` 