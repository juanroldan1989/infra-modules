# RBAC Module

This module ensures developers can interact with EKS **only in designated environments** (e.g.: dev), while **restricting access to prod and test** environments.

- Developers can deploy apps in DEV safely.
- No risk of modifying PROD or TEST infrastructure.
- IAM + Kubernetes RBAC ensures security at multiple levels.
- Scalable: You can add more developers and automate role assignments.
- Limit Namespace Access: Restrict developers to a single namespace (`dev-apps`).
- Ensure `kube-system` and other namespaces are off-limits.

## Features

- **IAM Role & Policy:** Creates an `IAM role` (`eks-{environment}-developer-role`) allowing access to specific EKS clusters.

- **AWS Authentication:** Automatically `maps` IAM roles to Kubernetes groups via the aws-auth ConfigMap.

- **Kubernetes RBAC:** Defines `Role` and `RoleBinding` for developers to deploy and manage applications.

- **Modular & Reusable:** Easily apply the `same configuration across different environments` (dev, test, prod).

- **Environment Isolation:** Prevents developers from making changes in test or prod environments.

## Resources Created

This module provisions the following AWS and Kubernetes resources:

### AWS Resources

- `aws_iam_role` → IAM role for EKS developers.

- `aws_iam_policy` → Policy granting limited access to EKS clusters.

- `aws_iam_role_policy_attachment` → Attaches the policy to the IAM role.

### Kubernetes Resources

- `kubectl_manifest` → Updates the aws-auth ConfigMap.

- `kubectl_manifest` → Creates a Role in Kubernetes with required permissions.

- `kubectl_manifest` → Creates a RoleBinding to associate IAM users with the developer role.

## Outputs

The module provides the following output:

`developer_role_arn`: ARN of the IAM role assigned to developers.

## Verify that developers can deploy applications in DEV but not access TEST or PROD.

1. Assume the `Developer` Role:

```bash
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT_ID:role/eks-dev-developer-role --role-session-name DevAccess
```

This will return temporary AWS credentials.

2. Set the Kubeconfig for the `DEV` Cluster:

```bash
aws eks update-kubeconfig --region REGION --name dev-eks-cluster
```

3. Test Access

- Check cluster info:

```bash
kubectl get nodes
```

- Try to deploy an application:

```bash
kubectl create deployment nginx --image=nginx --replicas=3 -n dev-apps
```

- Try deleting a production deployment (should fail):

```bash
kubectl delete deployment frontend -n prod
```

## Architecture Diagram

```bash
         +--------------------------------+
         | AWS IAM                        |
         |  - IAM Role (eks-dev-developer)|
         |  - IAM Policy (EKS Access)     |
         +--------------------------------+
                     |
                     v
         +------------------------------+
         | Amazon EKS                    |
         |  - aws-auth ConfigMap         |
         |  - Role: developer-role       |
         |  - RoleBinding: developer     |
         +------------------------------+
                     |
                     v
         +------------------------------+
         | Kubernetes Namespace          |
         |  - dev-apps                    |
         |  - Permissions: Deployments,  |
         |    Services, ConfigMaps       |
         +------------------------------+
```

## Additional Notes

- Ensure developers assume the correct IAM role before accessing EKS.

- This module only grants application deployment permissions; it does not allow modification of cluster-wide settings.

- Use `kubectl config use-context` to verify developer access in the dev environment.
