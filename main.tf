resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  bucket_prefix         = "${var.project_name}-${var.environment}"
  upload_bucket_name    = "${local.bucket_prefix}-upload-${random_id.suffix.hex}"
  processed_bucket_name = "${local.bucket_prefix}-processed-${random_id.suffix.hex}"
  lambda_function_name  = "${local.bucket_prefix}-processor"

  common_tags = {
    Environment = "dev"
    Project     = "image-processor"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_layer_version" "pillow_layer" {
  filename    = "${path.module}/pillow_layer.zip"
  layer_name  = "pillow_layer"
  description = "Shared utilities for Lambda functions"

  compatible_runtimes = [
    "python3.12"
  ]
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda_function.zip"
}

module "sns_notifications" {
  source = "./modules/sns_notifications"

  project_name            = var.project_name
  environment             = var.environment
  critical_alert_email    = var.alert_email
  performance_alert_email = var.alert_email
  log_alert_email         = var.alert_email

  tags = local.common_tags
}

module "s3_buckets" {
  source = "./modules/s3_buckets"

  upload_bucket_name    = local.upload_bucket_name
  processed_bucket_name = local.processed_bucket_name
  environment           = var.environment
  enable_versioning     = var.enable_s3_versioning

  tags = local.common_tags
}

module "log_alerts" {
  source = "./modules/log_alerts"

  function_name        = module.lambda_function.function_name
  log_group_name       = module.lambda_function.log_group_name
  log_alerts_topic_arn = module.sns_notifications.log_alerts_topic_arn
  metric_namespace     = var.metric_namespace
  tags                 = local.common_tags
}

module "cloudwatch_alarms" {
  source = "./modules/cloudwatch_alarms"

  function_name                = module.lambda_function.function_name
  critical_alerts_topic_arn    = module.sns_notifications.critical_alerts_topic_arn
  performance_alerts_topic_arn = module.sns_notifications.performance_alerts_topic_arn
  metric_namespace             = var.metric_namespace

  error_threshold                 = var.error_threshold
  duration_threshold_ms           = var.duration_threshold_ms
  throttle_threshold              = var.throttle_threshold
  concurrent_executions_threshold = var.concurrent_executions_threshold
  log_error_threshold             = var.log_error_threshold
  enable_no_invocation_alarm      = var.enable_no_invocation_alarm

  tags = local.common_tags
}

module "cloudwatch_metrics" {
  source = "./modules/cloudwatch_metrics"

  function_name    = module.lambda_function.function_name
  log_group_name   = module.lambda_function.log_group_name
  metric_namespace = var.metric_namespace
  enable_dashboard = var.enable_cloudwatch_dashboard
  aws_region       = var.aws_region

  tags = local.common_tags
}

module "lambda_function" {
  source = "./modules/lambda_function"

  function_name    = local.lambda_function_name
  aws_region       = var.aws_region
  handler          = "lambda.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  lambda_zip_path  = data.archive_file.lambda_zip.output_path
  lambda_layers    = [aws_lambda_layer_version.pillow_layer.arn]
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")

  upload_bucket_arn    = module.s3_buckets.upload_bucket_arn
  upload_bucket_id     = module.s3_buckets.upload_bucket_id
  processed_bucket_arn = module.s3_buckets.processed_bucket_arn
  processed_bucket_id  = module.s3_buckets.processed_bucket_id

  log_level          = var.log_level
  log_retention_days = var.log_retention_days

  tags = local.common_tags

}

resource "aws_lambda_permission" "allow_s3_invoke" {
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_buckets.upload_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.s3_buckets.upload_bucket_id

  lambda_function {
    lambda_function_arn = module.lambda_function.function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

module "observability_ec2" {
  source = "./modules/observability_ec2"
  count  = var.enable_observability ? 1 : 0

  name          = "${var.project_name}-${var.environment}"
  aws_region    = var.aws_region
  instance_type = var.observability_instance_type
  key_name      = var.observability_key_name
  allowed_cidrs = var.observability_allowed_cidrs
  assets_bucket = module.observability_assets[0].bucket_name
  assets_key    = module.observability_assets[0].object_key

  tags = local.common_tags
}

module "observability_assets" {
  source   = "./modules/observability_assets"
  count    = var.enable_observability ? 1 : 0

  name     = "${var.project_name}-${var.environment}"
  zip_path = "${path.root}/observability.zip"
  tags     = local.common_tags
}