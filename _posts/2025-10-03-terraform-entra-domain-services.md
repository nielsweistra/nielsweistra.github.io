---
layout: post
title: "Building Production-Ready Microsoft Entra Domain Services with Terraform"
date: 2025-10-03 16:30:00 +0200
categories: [Azure, Terraform, Authentication, Infrastructure]
tags: [azure, terraform, entra-id, domain-services, authentication, infrastructure-as-code, devops, security]
---

Microsoft Entra Domain Services (formerly Azure AD Domain Services) is a crucial component for organizations looking to implement hybrid identity solutions in Azure. While Azure provides managed domain controllers, setting up a production-ready deployment with proper security, monitoring, and networking requires careful planning and configuration.

In this post, I'll walk you through a comprehensive Terraform template I've developed that automates the deployment of Microsoft Entra Domain Services with enterprise-grade security, monitoring, and CI/CD integration.

## Why Terraform for Domain Services?

Traditional Azure portal deployments can be time-consuming and error-prone, especially when dealing with complex networking and security requirements. Infrastructure as Code (IaC) with Terraform provides:

- **Reproducible deployments** across environments
- **Version control** for infrastructure changes
- **Automated validation** and security scanning
- **Consistent configuration** and compliance
- **Documentation** through code

## Template Architecture

The template creates a complete authentication infrastructure with the following components:

### Core Infrastructure
- **Resource Group** with proper tagging and naming conventions
- **Virtual Network** with dedicated subnet for Domain Services
- **Network Security Groups** with least-privilege access rules
- **Microsoft Entra Domain Services** using the latest AzAPI provider

### Security Features
- **Key Vault** integration for certificate management
- **Secure LDAP (LDAPS)** support with automated certificate handling
- **Network isolation** with dedicated subnets and NSG rules
- **Role-based access control (RBAC)** for service principals

### Monitoring & Observability
- **Log Analytics Workspace** for centralized logging
- **Diagnostic settings** for comprehensive telemetry
- **Security alerts** for failed authentication attempts
- **Performance monitoring** with custom dashboards

### High Availability
- **Replica sets** support for multi-region deployments
- **Backup configuration** for Enterprise SKU
- **Health monitoring** and automated recovery

## Key Technical Challenges Solved

### 1. AzAPI Provider Requirement

One of the first challenges was discovering that Microsoft Entra Domain Services requires the AzAPI provider instead of the standard AzureRM provider:

```hcl
# ❌ This doesn't work
resource "azurerm_active_directory_domain_service" "main" {
  # Not available in AzureRM provider
}

# ✅ Correct approach
resource "azapi_resource" "domain_services" {
  type      = "Microsoft.AAD/DomainServices@2021-05-01"
  name      = var.domain_name
  parent_id = azurerm_resource_group.main.id
  # ... configuration
}
```

### 2. Variable Validation Constraints

Terraform variable validation has strict rules about cross-variable references. I had to refactor validation logic to only reference the variable being validated:

```hcl
# ❌ Invalid - references other variables
validation {
  condition = var.enable_secure_ldap == false || length(var.certificate_thumbprint) > 0
  error_message = "Certificate required when LDAP enabled."
}

# ✅ Valid - only references itself
validation {
  condition = var.certificate_thumbprint == "" || length(var.certificate_thumbprint) >= 40
  error_message = "Certificate thumbprint must be at least 40 characters."
}
```

### 3. CI/CD Without Azure Authentication

Creating a testing strategy that validates the template without requiring Azure credentials:

```bash
# CI/CD testing approach
ARM_SKIP_PROVIDER_REGISTRATION=true ARM_USE_CLI=false \
  terraform plan -var-file="terraform.tfvars.ci"
```

This allows complete validation of syntax, logic, and variable constraints in automated pipelines.

## Security Best Practices Implemented

### Network Security
```hcl
# Restrictive NSG rules for Domain Services
security_rule {
  name                       = "AllowLDAPS"
  priority                   = 1001
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range         = "*"
  destination_port_range    = "636"
  source_address_prefixes   = var.allowed_source_addresses
  destination_address_prefix = var.subnet_address_prefix
}
```

### Identity & Access Management
```hcl
# Custom RBAC role for Domain Services operators
resource "azurerm_role_definition" "domain_services_operator" {
  name        = "Domain Services Operator"
  scope       = azurerm_resource_group.main.id
  description = "Manage domain services resources"

  permissions {
    actions = [
      "Microsoft.AAD/domainServices/read",
      "Microsoft.AAD/domainServices/write",
      "Microsoft.AAD/domainServices/restart/action"
    ]
    not_actions = [
      "Microsoft.AAD/domainServices/delete"
    ]
  }
}
```

### Certificate Management
```hcl
resource "azurerm_key_vault" "main" {
  # Security features
  enable_rbac_authorization   = true
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90

  # Network access controls
  public_network_access_enabled = false
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.domain_services.id]
  }
}
```

## Development Experience Features

### Cross-Platform Tooling
The template includes both Makefile for Linux/macOS and PowerShell scripts for Windows:

```bash
# Linux/macOS
make test-ci      # Run CI validation
make security     # Security scan
make docs         # Generate documentation

# Windows
.\scripts.ps1 test-ci    # Run CI validation
.\scripts.ps1 security   # Security scan
.\scripts.ps1 docs       # Generate documentation
```

### Pre-commit Hooks
Automated quality gates using pre-commit hooks:

```yaml
repos:
- repo: https://github.com/antonbabenko/pre-commit-terraform
  rev: v1.83.5
  hooks:
    - id: terraform_fmt
    - id: terraform_validate
    - id: terraform_tfsec
    - id: terraform_docs
```

### Comprehensive Documentation
The template includes extensive documentation:
- **Architecture diagrams** and technical details
- **Configuration guide** with environment-specific examples
- **Security best practices** and compliance guidelines
- **Troubleshooting guide** with common issues and solutions

## CI/CD Pipeline Integration

### GitHub Actions
```yaml
name: 'Terraform Validation'

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  terraform-validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: hashicorp/setup-terraform@v3
    
    - name: Terraform Validate
      run: terraform validate
      
    - name: Security Scan
      uses: aquasecurity/tfsec-action@v1.0.3
      
    - name: Plan with CI Config
      run: terraform plan -var-file="terraform.tfvars.ci"
      env:
        ARM_SKIP_PROVIDER_REGISTRATION: true
        ARM_USE_CLI: false
```

### Azure DevOps
The template includes Azure DevOps pipeline with:
- Multi-stage validation
- Security compliance checks
- Automated documentation generation
- Cost estimation integration

## Real-World Usage Examples

### Development Environment
```hcl
# terraform.tfvars for development
resource_group_name = "rg-entradomain-dev"
domain_name        = "dev.contoso.local"
sku               = "Standard"
enable_secure_ldap = false
replica_sets      = []
```

### Production Environment
```hcl
# terraform.tfvars for production
resource_group_name = "rg-entradomain-prod"
domain_name        = "contoso.local"
sku               = "Premium"
enable_secure_ldap = true

replica_sets = [
  {
    location = "North Europe"
    subnet_id = "/subscriptions/.../subnets/replica-subnet"
  }
]

notification_settings = {
  notify_dc_admins      = true
  notify_global_admins  = true
  additional_recipients = ["ops-team@contoso.com"]
}
```

## Lessons Learned

### 1. Provider Limitations
Not all Azure services are available in the standard AzureRM provider. Always check the AzAPI provider for newer services.

### 2. Validation Complexity
Terraform's variable validation system has constraints that require careful design of validation logic.

### 3. CI/CD Strategy
Creating effective CI/CD pipelines for infrastructure requires balancing security with automation capabilities.

### 4. Documentation is Critical
Infrastructure templates need comprehensive documentation for successful adoption and maintenance.

## Performance and Cost Considerations

### SKU Selection
- **Standard**: Development and testing workloads
- **Enterprise**: Production workloads with forest trusts
- **Premium**: Mission-critical applications requiring highest performance

### Cost Optimization
```hcl
# Use Infracost for cost estimation
infracost breakdown --path=. --format=json
```

The template includes cost estimation integration for budget planning.

## Future Enhancements

### Planned Features
- **Terraform Cloud integration** for remote state management
- **Azure Policy integration** for compliance automation
- **Azure Sentinel integration** for advanced security monitoring
- **Multi-tenant support** for managed service providers

### Community Contributions
The template is open-source and welcomes contributions for:
- Additional monitoring dashboards
- Extended security configurations
- Integration with other Azure services
- Documentation improvements

## Getting Started

### Prerequisites
- Azure subscription with Global Administrator rights
- Terraform v1.5.0+
- Azure CLI installed and configured

### Quick Start
```bash
# Clone the repository
git clone https://github.com/ITlusions/ITL.AuthServices.git
cd ITL.AuthServices

# Configure your deployment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply
```

### Testing Without Azure
```bash
# Validate configuration without Azure authentication
.\scripts.ps1 test-ci
```

## Conclusion

Building production-ready infrastructure for Microsoft Entra Domain Services requires attention to security, monitoring, networking, and operational concerns. This Terraform template addresses these challenges while providing a foundation for scalable, maintainable authentication infrastructure.

The template demonstrates several important patterns:
- **Security-first design** with defense in depth
- **Operational excellence** through comprehensive monitoring
- **Developer experience** with cross-platform tooling
- **CI/CD integration** for automated validation and deployment

Whether you're implementing hybrid identity for the first time or looking to improve your existing infrastructure automation, this template provides a solid foundation for Microsoft Entra Domain Services in Azure.

## Resources

- **GitHub Repository**: [ITL.AuthServices](https://github.com/ITlusions/ITL.AuthServices)
- **Azure Documentation**: [Microsoft Entra Domain Services](https://docs.microsoft.com/en-us/azure/active-directory-domain-services/)
- **Terraform Registry**: [AzAPI Provider](https://registry.terraform.io/providers/Azure/azapi/latest)
- **Security Guide**: [Azure AD Domain Services Security](https://docs.microsoft.com/en-us/azure/active-directory-domain-services/secure-your-domain)

---

*Have questions about implementing Microsoft Entra Domain Services with Terraform? Feel free to reach out or contribute to the project on GitHub!*