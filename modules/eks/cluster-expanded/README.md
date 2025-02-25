# EKS Cluster Expanded Module

This module uses `AWS` Provider and configures individually all resources required to setup a networking foundation.

## EKS Control plane

- `private_subnets` use a NAT Gateway to allow outbound internet access while keeping them private.
- `intra_subnets` do not use a NAT Gateway or Internet Gateway, meaning they are completely isolated. These subnets are strictly internal, ideal for services that should never communicate with the public internet.

### Why Does Your EKS Cluster Need intra_subnets?

When deploying EKS, AWS recommends using intra subnets for control plane nodes because:

✅ The EKS control plane should be isolated from public traffic.
✅ It does not need to access the internet directly.
✅ Only worker nodes and internal services should communicate with it.

By defining intra_subnets, the EKS control plane will be provisioned in these subnets, making your architecture more secure.

## EKS Node Group - Capacity Types

`ON_DEMAND`

- Specifies that the managed node group should use On-Demand Instances.
- These instances are charged at the standard hourly rate without any long-term commitment.

`SPOT`

- Specifies that the managed node group should use Spot Instances.
- Spot Instances allow you to use unused EC2 capacity at a discounted rate
  but can be interrupted by AWS with a two-minute warning if capacity is reclaimed.
- Spot Instances are suitable for workloads that can tolerate interruptions,
  such as stateless, fault-tolerant, or batch processing tasks.

## Notes

Really good Gruntwork repository for references and also how to add comments within files:

https://github.com/gruntwork-io/terragrunt-infrastructure-modules-example/blob/master/modules/ecs-fargate-service/main.tf

## Terraform best practices

https://www.terraform-best-practices.com/code-structure

https://cloud.google.com/docs/terraform/best-practices/general-style-structure

- Terraform pre-commit hooks:

https://github.com/antonbabenko/pre-commit-terraform?tab=readme-ov-file#how-to-install

terraform fmt
terraform validate
terraform tf_lint
terraform tf_sec
infracost_breakedown

- Kubernetes "Lens" Desktop App to inspect clusters and resources.
