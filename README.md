# infra-modules

## Overview

This repository contains custom `Terraform` modules designed to provision various infrastructure components.

Each module encapsulates best practices and reusable configurations to ensure **consistency, maintainability and scalability** across different environments.

## Module Structure

Each module is organized into a dedicated folder containing the following files:

1. `main.tf` – Defines the core resources and configurations required for the module.
2. `variables.tf` – Declares the required input variables, allowing customization of module parameters.
3. `outputs.tf` – Specifies the outputs produced by the module, making them accessible for other configurations.
4. `README.md` – Provides details on the module's usage, input variables, and expected outputs.

## Usage

To provision a specific module within a project, follow these steps:

1. Create folder for your infrastructure component

For example, to provision `networking` resources, create a directory named `networking`:

```bash
mkdir networking && cd networking
```

2. Within the `networking` folder, define a `terragrunt.hcl` configuration file:

```bash
include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/networking"
}

inputs = {
  # Environment variables
  aws_account_id = include.root.locals.aws_account_id
  aws_region     = include.root.locals.aws_region
  env            = include.root.locals.env

  # Custom module-specific inputs
  eks_name = "none"
}
```

3. Run the following command to provision the infrastructure defined by the selected module:


```bash
terragrunt apply
```

- This will initialize and apply the module, provisioning the necessary infrastructure components in your `AWS` environment.

## Best Practices

- Follow modularization principles to keep configurations `DRY` (Don't Repeat Yourself) and maintainable.

- Use `Terragrunt` to simplify configuration management and enforce best practices.

- Leverage `remote state management` with an appropriate backend (e.g.: `AWS S3 with DynamoDB locking`) to maintain state consistency across environments.

- Use input validation in `variables.tf` to enforce required values and constraints.

## Contributing

Contributions are welcome and greatly appreciated! If you would like to contribute to this project, please follow the guidelines within [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the terms of the [MIT License](LICENSE).
