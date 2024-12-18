variable "nextcloud_role_arn" {
  description = "ARN of the IAM role used by Nextcloud instances"
  type        = string
  default     = "arn:aws:iam::123456789012:role/your-nextcloud-role" # Set your default ARN here
}