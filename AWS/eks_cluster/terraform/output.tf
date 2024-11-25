output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
  description = "Public IP of the Bastion server"
}

output "rds_endpoint" {
  value       = aws_db_instance.rds_instance.address
  description = "DNS endpoint of the RDS instance"
}

output "ec2_access_eks_role_arn" {
  value       = aws_iam_role.ec2_access_eks.arn
  description = "The ARN of the ec2_access_eks role"
}
