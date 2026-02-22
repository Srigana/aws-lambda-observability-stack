resource "aws_s3_bucket" "assets" {
  bucket        = "${var.name}-observability-assets"
  force_destroy = true

  tags = merge(var.tags, {
    Name = "${var.name}-observability-assets"
  })
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "zip" {
  bucket = aws_s3_bucket.assets.id
  key    = "observability.zip"
  source = var.zip_path
}