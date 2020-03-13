output "server_arn" {
  value       = aws_transfer_server.default.arn
  description = "ARN of the transfer server"
}

output "user_arn" {
  value = {
    for transfer_user in aws_transfer_user.default :
    transfer_user.user_name => transfer_user.arn
  }
  description = "ARN of the transfer user"
}
