output "server_id" {
  value       = aws_transfer_server.default.id
  description = "Server ID (stable identifier; must not change)."
}

output "server_arn" {
  value       = aws_transfer_server.default.arn
  description = "ARN of the transfer server."
}

output "user_arns" {
  value       = { for name, u in aws_transfer_user.default : name => u.arn }
  description = "ARNs of the transfer users."
}

# output "host_key_ids" {
#   value       = var.manage_host_keys ? [for hk in aws_transfer_host_key.managed : hk.host_key_id] : []
#   description = "IDs of managed host keys attached to this server."
# }
