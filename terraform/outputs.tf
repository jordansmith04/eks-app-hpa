output "alb_controller_role_arn" {
  description = "The ARN of the IAM role to be used by the AWS LoadBalancer Controller service account."
  value       = aws_iam_role.alb_controller_role.arn
}