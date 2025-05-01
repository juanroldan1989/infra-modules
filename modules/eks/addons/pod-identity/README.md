# EKS Pod Identity Addon

This resource enables the `EKS Pod Identity` Webhook as an EKS addon.

It allows Kubernetes pods to assume `IAM` roles using service account credentials, which is
essential for managing access to AWS resources.

It is installed in the `kube-system` namespace.

## Check for updates and compatibilities

Run this command to get the latest version of the addon and its compatibilities with EKS versions:

```bash
aws eks describe-addon-versions --region <region-name> --addon-name eks-pod-identity-agent
```

```bash
{
  "addons": [
    {
      "addonName": "eks-pod-identity-agent",
      "type": "security",
      "addonVersions": [
        ...
      ]
    }
  ]
}
```

## Addon definition

Addon defined within `EKS` cluster module itself:

```bash
...

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      addon_version = "v1.2.0-eksbuild.1"
    }
    kube-proxy             = {}
    vpc-cni                = {}
  }

...
```
