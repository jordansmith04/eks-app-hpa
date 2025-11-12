terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# AWS LoadBalancer Controller IAM Role Configuration (IRSA)

# IAM Policy
resource "aws_iam_policy" "alb_controller_policy" {
  name_prefix = "EKS-ALB-Controller-"
  description = "Policy for AWS LoadBalancer Controller to manage ALBs."

  # Standard IAM policy required by the controller
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate", "acm:ListCertificates", "acm:GetCertificate",
          "ec2:AuthorizeSecurityGroupIngress", "ec2:CreateSecurityGroup", "ec2:CreateTags",
          "ec2:DeleteTags", "ec2:DeleteSecurityGroup", "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses", "ec2:DescribeAvailabilityZones", "ec2:DescribeInternetGateways",
          "ec2:DescribeNetworkInterfaces", "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets",
          "ec2:DescribeTags", "ec2:DescribeVpcs", "ec2:ModifySecurityGroupRules",
          "ec2:RevokeSecurityGroupIngress", "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:AddTags", "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateLoadBalancer", "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:CreateTargetGroup", "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteLoadBalancer", "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DeleteTargetGroup", "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeListenerCertificates", "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancers", "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeRules", "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTargetGroups", "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth", "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyLoadBalancerAttributes", "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:ModifyTargetGroup", "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets", "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:RemoveTags", "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups", "elasticloadbalancing:SetSubnets",
          "iam:CreateServiceLinkedRole", "iam:GetServerCertificate", "iam:ListServerCertificates",
          "wafv2:GetWebACLForResource", "wafv2:GetWebACL", "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL", "tag:GetResources", "tag:TagResources", "tag:UntagResources"
        ]
        Resource = "*"
      },
    ]
  })
}

# Assume Role Policy Document
# Allows the Kubernetes service account 'aws-load-balancer-controller'
# to assume this role, authenticated via the EKS OIDC provider.
data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.eks_cluster_oidc_issuer_url}"]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_cluster_oidc_issuer_url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

# Create IAM Role
resource "aws_iam_role" "alb_controller_role" {
  name               = "eks-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "alb_controller_attachment" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

