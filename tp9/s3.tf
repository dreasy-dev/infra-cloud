data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "nextcloud_bucket" {
  bucket = "${local.user}-nextcloud-bucket"

  tags = {
    Name  = "Nextcloud Bucket"
    Owner = local.user
  }
}

resource "aws_s3_bucket_policy" "nextcloud_bucket_policy" {
  bucket = aws_s3_bucket.nextcloud_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowNextcloudAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload"
        ]
        Resource = [
          aws_s3_bucket.nextcloud_bucket.arn,
          "${aws_s3_bucket.nextcloud_bucket.arn}/*"
        ],
        Condition = {
          StringNotLike = {
            "aws:UserAgent": ["AWS Console*", "AWS-Management-Console*"]
          }
        }
      },
      {
        Sid       = "AllowConsoleListOnly"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [aws_s3_bucket.nextcloud_bucket.arn],
        Condition = {
          StringLike = {
            "aws:UserAgent": ["AWS Console*", "AWS-Management-Console*"]
          }
        }
      }
    ]
  })
}