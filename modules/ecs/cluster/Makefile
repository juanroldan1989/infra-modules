.PHONY: help test fmt validate lint security init clean install

# Default target
help:
	@echo "ECS Cluster Module - Makefile Commands"
	@echo "======================================="
	@echo ""
	@echo "Testing:"
	@echo "  make test          Run all static analysis tests"
	@echo "  make fmt           Format Terraform files"
	@echo "  make validate      Validate Terraform configuration"
	@echo "  make lint          Run TFLint"
	@echo "  make security      Run security scans (TFSec + Checkov)"
	@echo ""
	@echo "Setup:"
	@echo "  make install       Install testing tools"
	@echo "  make init          Initialize Terraform and TFLint"
	@echo "  make clean         Clean up temporary files"

# Run all static analysis tests
test:
	@./tests/static-analysis.sh

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive

# Validate Terraform configuration
validate: init
	@echo "Validating Terraform configuration..."
	@terraform validate

# Run TFLint
lint:
	@echo "Running TFLint..."
	@tflint --init
	@tflint --recursive

# Run security scans
security:
	@echo "Running TFSec security scan..."
	@tfsec . --format=default
	@echo ""
	@echo "Running Checkov policy scan..."
	@checkov -d . --framework terraform

# Initialize Terraform
init:
	@terraform init -backend=false

# Clean up
clean:
	@echo "Cleaning up..."
	@rm -rf .terraform
	@rm -rf .tflint.d
	@find . -name "*.tfstate" -type f -delete
	@find . -name "*.tfstate.backup" -type f -delete
	@echo "Cleanup complete"

# Install testing tools (macOS)
install:
	@echo "Installing testing tools..."
	@command -v terraform >/dev/null 2>&1 || brew install terraform
	@command -v tflint >/dev/null 2>&1 || brew install tflint
	@command -v tfsec >/dev/null 2>&1 || brew install tfsec
	@command -v checkov >/dev/null 2>&1 || pip3 install checkov
	@echo "Installation complete. Run 'make init' to initialize."
