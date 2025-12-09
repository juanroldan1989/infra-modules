# Testing Guide for Terraform Infrastructure Modules

This guide provides comprehensive testing strategies for all Terraform modules in this repository.

## Table of Contents
1. [Testing Philosophy](#testing-philosophy)
2. [Test Levels](#test-levels)
3. [Static Analysis Setup](#static-analysis-setup)
4. [Running Tests](#running-tests)
5. [CI/CD Integration](#cicd-integration)
6. [Troubleshooting](#troubleshooting)

## Testing Philosophy

Testing Terraform modules ensures:
- **Security**: No vulnerabilities or misconfigurations
- **Quality**: Consistent code style and best practices
- **Reliability**: Modules work as expected
- **Compliance**: Adherence to organizational policies

## Test Levels

### 1. Static Analysis (Implemented ✅)
Fast, pre-deployment checks without requiring cloud credentials.

**Tools Used:**
- **Terraform Format**: Code formatting consistency
- **Terraform Validate**: Syntax and configuration validation
- **TFLint**: Terraform linting with AWS rules
- **TFSec**: Security vulnerability scanning
- **Checkov**: Policy and compliance checks

**Example: ECS Cluster Module**
```bash
cd modules/ecs/cluster
make test
```

### 2. Unit Tests (Planned 📋)
Test individual resources in isolation using `terraform plan`.

**Approach:**
- Create test fixtures with sample inputs
- Validate outputs match expectations
- Check resource attributes

**Example Structure:**
```
modules/ecs/cluster/
  tests/
    unit/
      main_test.go          # Terratest unit tests
      fixtures/
        basic.tfvars        # Basic configuration
        advanced.tfvars     # Advanced configuration
```

### 3. Integration Tests (Planned 📋)
Full deployment tests using Terratest in isolated test environments.

**Approach:**
- Deploy to real AWS test account
- Validate resources created correctly
- Test functionality (e.g., ECS tasks can run)
- Destroy resources after testing

**Example:**
```go
// modules/ecs/cluster/tests/integration/cluster_test.go
func TestECSCluster(t *testing.T) {
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../../",
    })
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Validate cluster exists
    clusterName := terraform.Output(t, terraformOptions, "cluster_name")
    // ... additional assertions
}
```

## Static Analysis Setup

### Prerequisites

Install required tools:

```bash
# macOS
brew install terraform tflint tfsec
pip3 install checkov

# Linux
# Install Terraform from https://terraform.io
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
brew install tfsec  # or download from GitHub releases
pip3 install checkov

# Windows
choco install terraform tflint tfsec
pip install checkov
```

### Per-Module Configuration

Each module should have:

1. **`.tflint.hcl`**: TFLint configuration
```hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```

2. **`.tfsec/config.yml`**: TFSec configuration
```yaml
exclude:
  # Add exclusions for false positives
severity: LOW
```

3. **`.checkov.yml`**: Checkov configuration
```yaml
skip-check: []
compact: true
framework: [terraform]
```

4. **`tests/static-analysis.sh`**: Test execution script
5. **`Makefile`**: Convenient test commands

## Running Tests

### Individual Module Testing

```bash
# Navigate to module
cd modules/ecs/cluster

# Run all tests
make test

# Run specific tests
make fmt        # Format check
make validate   # Terraform validation
make lint       # TFLint
make security   # TFSec + Checkov

# Install tools
make install

# Clean up
make clean
```

### Workspace-Wide Testing

```bash
# Test all modules
for module in modules/*/; do
    echo "Testing ${module}..."
    (cd "${module}" && make test)
done
```

### Manual Tool Execution

```bash
# Format check and fix
terraform fmt -check -recursive  # Check only
terraform fmt -recursive         # Fix formatting

# Validation
terraform init -backend=false
terraform validate

# TFLint
tflint --init
tflint --recursive

# TFSec
tfsec . --format=default

# Checkov
checkov -d . --framework terraform
```

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/terraform-tests.yml`:

```yaml
name: Terraform Module Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  static-analysis:
    name: Static Analysis
    runs-on: ubuntu-latest

    strategy:
      matrix:
        module:
          - modules/ecs/cluster
          - modules/ecs/external-service
          - modules/networking
          # Add all modules

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Setup TFLint
        uses: terraform-linters/setup-tflint@v3
        with:
          tflint_version: v0.44.0

      - name: Install TFSec
        run: |
          curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

      - name: Install Checkov
        run: pip3 install checkov

      - name: Run Tests
        run: |
          cd ${{ matrix.module }}
          chmod +x tests/static-analysis.sh
          ./tests/static-analysis.sh
```

### Pre-Commit Hooks

Create `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_tfsec
      - id: terraform_checkov
```

Install and enable:
```bash
pip install pre-commit
pre-commit install
```

## Test Results Interpretation

### Success Indicators
- ✓ All format checks pass
- ✓ No validation errors
- ✓ TFLint: No errors or warnings
- ✓ TFSec: No HIGH/CRITICAL vulnerabilities
- ✓ Checkov: All policy checks pass

### Common Issues and Fixes

#### Formatting Issues
```bash
# Fix automatically
terraform fmt -recursive
```

#### TFLint Warnings
```hcl
# Add rule exceptions in .tflint.hcl
rule "aws_instance_previous_type" {
  enabled = false
}
```

#### TFSec Findings
```yaml
# Add to .tfsec/config.yml
exclude:
  - aws-ecs-enable-container-insight  # If not needed
```

#### Checkov Failures
```yaml
# Add to .checkov.yml
skip-check:
  - CKV_AWS_158  # CloudWatch encryption (if not required)
```

## Troubleshooting

### Tool Installation Issues

**TFLint plugin download fails:**
```bash
# Manual plugin installation
mkdir -p ~/.tflint.d/plugins
cd ~/.tflint.d/plugins
# Download from GitHub releases
```

**Checkov Python conflicts:**
```bash
# Use virtual environment
python3 -m venv venv
source venv/bin/activate
pip install checkov
```

### Test Execution Issues

**Terraform init fails:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Use backend=false for static analysis
terraform init -backend=false
```

**TFLint fails with module errors:**
```bash
# Initialize TFLint plugins
tflint --init

# Run with module support
tflint --recursive
```

## Best Practices

1. **Run tests before every commit**
   - Use pre-commit hooks
   - Fast feedback on issues

2. **Fix formatting immediately**
   - Run `terraform fmt -recursive` regularly
   - Prevents trivial PR feedback

3. **Review security findings carefully**
   - Don't blindly skip security checks
   - Document why exceptions are made

4. **Keep tools updated**
   - New rules catch new issues
   - Better AWS resource support

5. **Document test failures**
   - Create issues for legitimate findings
   - Track security debt

6. **Test in isolation**
   - Each module should be independently testable
   - Don't rely on external dependencies

7. **Use consistent naming**
   - Follow naming conventions enforced by TFLint
   - Improves code readability

## Next Steps

### Immediate Actions
1. ✅ Static analysis implemented for `ecs/cluster`
2. 📋 Roll out to all modules: `ecs/external-service`, `networking`, etc.
3. 📋 Set up pre-commit hooks
4. 📋 Add GitHub Actions workflow

### Future Enhancements
1. 📋 Implement unit tests with Terratest
2. 📋 Create integration test suite
3. 📋 Add cost estimation with Infracost
4. 📋 Security scanning in CI/CD
5. 📋 Automated documentation generation

## Resources

- [Terraform Testing Best Practices](https://www.terraform.io/docs/language/modules/testing-experiment.html)
- [TFLint Documentation](https://github.com/terraform-linters/tflint)
- [TFSec Documentation](https://aquasecurity.github.io/tfsec/)
- [Checkov Documentation](https://www.checkov.io/)
- [Terratest Documentation](https://terratest.gruntwork.io/)

## Module-Specific Test Status

| Module | Static Analysis | Unit Tests | Integration Tests |
|--------|----------------|------------|-------------------|
| ecs/cluster | ✅ | 📋 | 📋 |
| ecs/external-service | 📋 | 📋 | 📋 |
| ecs/monitoring | 📋 | 📋 | 📋 |
| networking | 📋 | 📋 | 📋 |
| database | 📋 | 📋 | 📋 |
| eks/* | 📋 | 📋 | 📋 |

✅ = Implemented | 📋 = Planned | ❌ = Not Applicable
