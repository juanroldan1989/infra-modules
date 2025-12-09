terraform {
  required_version = ">= 1.0"
}

module "ecs" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ecs.git?ref=e7647af6055b50b49007ec4d60fb49227bbfd449" # version 4.1.3

  cluster_name = "${var.env}-${var.aws_region}-${var.cluster_name}"

  # Allocate 20% capacity to FARGATE and then
  # split 50/50 the remaining 80% capacity
  # between FARGATE and FARGATE_SPOT.

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        base   = 20
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
}
