variable "eks_cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL of the EKS cluster (e.g., abcdef0123456789.sk1.us-east-2.eks.amazonaws.com)."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}