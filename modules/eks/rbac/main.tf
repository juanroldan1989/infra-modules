# 1. Create IAM role specific to each environment, allowing developers to assume it.

# - Creates an IAM role eks-${var.env}-developer-role.
# - Allows **only approved users** (from `developer_iam_users`) to assume the role.
# - Restricts access **only to the assigned EKS cluster**

resource "aws_iam_role" "eks_developer" {
  name               = "eks-${var.env}-developer-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = var.developer_iam_users
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "eks_policy" {
  name        = "eks-${var.env}-developer-policy"
  description = "Policy for EKS Developer Role in ${var.env}"
  policy      = data.aws_iam_policy_document.eks_access.json
}

data "aws_iam_policy_document" "eks_access" {
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:DescribeNodegroup",
      "eks:AccessKubernetesApi"
    ]
    resources = ["arn:aws:eks:${var.aws_region}:${var.aws_account_id}:cluster/${var.env}-${var.eks_name}"]
  }

  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["arn:aws:eks:${var.aws_region}:${var.aws_account_id}:cluster/prod-*"]
  }
}

resource "aws_iam_role_policy_attachment" "eks_attach" {
  policy_arn = aws_iam_policy.eks_policy.arn
  role       = aws_iam_role.eks_developer.name
}

# 2. Update EKS `aws-auth` ConfigMap to:

# - Map `eks-${var.env}-developer-role` IAM role to Kubernetes group `developers`.
# - Ensure secure authentication to the EKS cluster.

resource "kubectl_manifest" "aws_auth_configmap" {
  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks_developer.arn}
      username: developer
      groups:
        - developers
YAML
}

# 3. Defines RBAC roles and permissions for developers.

# - Developers can only deploy & manage workloads in `namespace` namespace.
# - They cannot delete cluster nodes, modify networking or touch other namespaces.

resource "kubectl_manifest" "developer_role" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ${var.namespace}
  name: developer-role
rules:
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "daemonsets"]
    verbs: ["get", "list", "watch", "create", "update", "delete"]
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "secrets"]
    verbs: ["get", "list", "watch", "create", "update", "delete"]
YAML
}

resource "kubectl_manifest" "developer_rolebinding" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: ${var.namespace}
  name: developer-role-binding
subjects:
  - kind: Group
    name: developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
YAML
}

# 4. Restrict access to `kube-system` namespace.

# - Developers can see (get, list) all namespaces, but they cannot create, delete, or modify them.

resource "kubectl_manifest" "namespace_restriction" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: kube-system
  name: restrict-developer-access
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list"]
    resourceNames: ["default", "kube-system"]
YAML
}
