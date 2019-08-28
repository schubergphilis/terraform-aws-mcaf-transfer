output "server_arn" {
  value       = aws_transfer_server.default.arn
  description = "ARN of the transfer server"
}

output "user_arn" {
  value       = aws_transfer_user.default.arn
  description = "ARN of the transfer user"
}
