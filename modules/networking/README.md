# Networking module

This module uses `terraform-aws-modules/vpc/aws` module to simplify configuration and resource management in a single module.

## EKS Requirements

The subnets where `EKS` worker nodes and load balancers operate must meet specific requirements:

1. `Private subnets`: Typically used for EKS worker nodes for security.
2. `Public subnets`: Used for load balancers (e.g., ALB) to expose services to the internet.
3. `Tags`:

- `kubernetes.io/role/elb`: For public subnets to enable external load balancers.
- `kubernetes.io/role/internal-elb`: For private subnets to enable internal load balancers.
- `kubernetes.io/cluster/<eks-cluster-name>`: Required for all subnets to associate them with the EKS cluster.

```bash
                           +-----------------------------+
                           |         Internet           |
                           +-----------------------------+
                                      |
                                      |
                           +-----------------------------+
                           |  aws_internet_gateway.igw   |
                           +-----------------------------+
                                      |
                          +-----------+-----------+
                          |                       |
        +------------------------+                |
        | aws_route_table.public |                |
        +------------------------+                |
                          |                       |
               +---------------------+            |
               |   Public Subnets    |            |
               +---------------------+            |
               |                     |            |
     +----------------+   +----------------+      |
     | aws_subnet     |   | aws_subnet     |      |
     | public_zone1   |   | public_zone2   |      |
     +----------------+   +----------------+      |
           |                                        |
           |                                        |
 +----------------------------+                    |
 | aws_nat_gateway.nat        | <------------------+
 +----------------------------+
           |
 +----------------------------+
 | aws_eip.nat                |
 +----------------------------+
           |
 +----------------------------+
 | aws_route_table.private    |
 +----------------------------+
           |
   +---------------------+
   |   Private Subnets    |
   +---------------------+
   |                     |
+----------------+   +----------------+
| aws_subnet     |   | aws_subnet     |
| private_zone1  |   | private_zone2  |
+----------------+   +----------------+

```

1. Internet Gateway: Provides internet access to resources in public subnets.

2. Public Subnets: Public-facing resources are hosted here. They are connected to the public route table and the Internet Gateway.

3. Private Subnets: Internal resources are hosted here, connected to the private route table.

4. NAT Gateway: Allows private subnets to access the internet securely for outbound traffic. It resides in a public subnet (zone1) and uses an Elastic IP (EIP).

5. Route Tables: Define routing rules:

- Public Route Table: Routes traffic from public subnets to the Internet Gateway.
- Private Route Table: Routes traffic from private subnets to the NAT Gateway.

6. Subnets: Include public and private subnets in two availability zones (zone1 and zone2), ensuring high availability.
