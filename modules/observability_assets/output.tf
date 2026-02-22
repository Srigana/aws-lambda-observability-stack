output "bucket_name" {
  value = aws_s3_bucket.assets.bucket
}

output "object_key" {
  value = aws_s3_object.zip.key
}