# Static Analysis Tests for ECS Cluster Module

This directory contains automated tests for the ECS cluster Terraform module.

## Test Types

### Static Analysis (`static-analysis.sh`)
Comprehensive static analysis including:
- **Terraform Format Check**: Ensures consistent code formatting
- **Terraform Validation**: Validates configuration syntax and logic
- **TFLint**: Advanced linting with AWS best practices
- **TFSec**: Security vulnerability scanning
- **Checkov**: Policy and compliance checks
- **Code Quality Checks**: TODOs, hardcoded secrets, documentation completeness

## Prerequisites

Install required tools:

```bash
python3 -m venv .venv

source .venv/bin/activate

make install # Terraform, TFLint, TFSec, Checkov
```

## Running Tests

### Run all static analysis tests:

```bash
./tests/static-analysis.sh
```

### Run individual checks:

```bash
# Format check
terraform fmt -check -recursive

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

## Test Output

The script provides:
- ✓ Green checkmarks for passing tests
- ✗ Red crosses for failing tests
- Detailed error messages for failures
- Summary of passed/failed tests

## CI/CD Integration

This test suite is designed for easy CI/CD integration:

```yaml
# GitHub Actions example
- name: Run Static Analysis
  run: |
    cd modules/ecs/cluster
    ./tests/static-analysis.sh
```

## Troubleshooting

### TFLint Init Failed
```bash
cd modules/ecs/cluster
tflint --init
```

### Format Issues
```bash
terraform fmt -recursive
```

### Security Findings
Review and fix security issues reported by TFSec/Checkov, or add exceptions in `.tfsec/config.yml` if false positives.

## Best Practices

1. **Run tests before committing**: Use pre-commit hooks
2. **Fix format issues immediately**: Run `terraform fmt -recursive`
3. **Document all variables**: Every variable must have a description
4. **Review security findings**: Don't ignore TFSec/Checkov warnings
5. **Keep tools updated**: Regularly update TFLint, TFSec, Checkov

## Next Steps

After static analysis passes:
- Unit tests (planned)
- Integration tests with Terratest (planned)
- End-to-end deployment tests (planned)
