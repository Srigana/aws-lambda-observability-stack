# AWS Serverless Image Processor + Observability (Prometheus/Grafana)

A serverless image-processing pipeline on AWS (S3 → Lambda) with production-style monitoring.

CloudWatch provides the source metrics/logs, and an optional Prometheus stack (YACE → Prometheus → Grafana + Alertmanager) makes the metrics easy to demo and dashboard.

## Architecture

**Flow**
1. Upload image to **Source S3**
2. **S3 event** triggers **Lambda**
3. Lambda processes image (resize/convert/compress)
4. Output saved to **Destination S3**
5. Logs/metrics → **CloudWatch**
6. CloudWatch metrics → **YACE** → **Prometheus** → **Grafana**
7. Alerts → **Alertmanager** (email/web UI)

> Add your architecture diagram here:
> `![Architecture](./docs/architecture.png)`

## Tech Stack

- AWS: S3, Lambda, IAM, CloudWatch, SNS (optional)
- IaC: Terraform (modular)
- Observability: Prometheus, Alertmanager, Grafana, YACE (CloudWatch exporter)
- Runtime: Python + Pillow

## Repository Structure

```text
demo-images/            Test images used to trigger the pipeline

modules/                Terraform modules (reusable building blocks)
  cloudwatch_alarms/     CloudWatch alarms (metrics-based)
  cloudwatch_metrics/    Dashboards, metric filters, custom metrics
  lambda_function/       Lambda, IAM, log group
  log_alerts/            Log-based metric filters + alarms
  s3_buckets/            Source/Destination buckets + security settings
  sns_notifications/     SNS topics + email subscriptions
  observability_ec2/     EC2 module that installs Docker + runs the monitoring stack

observability/           Runtime configs for Prometheus / Alertmanager / Grafana / YACE
  docker-compose.yml     Runs YACE + Prometheus + Alertmanager + Grafana
  .env.example           Example env vars (don’t commit real secrets)
  prometheus/            Prometheus config + alert rules
  alertmanager/          Alertmanager routing + SMTP config
  grafana/               Datasource + dashboard provisioning
  yace/                  CloudWatch exporter config

lambda.py                Lambda handler source (local copy)
*.zip                    Deployment artifacts (Lambda + Pillow layer)
main.tf / variables.tf    Root Terraform orchestration + inputs/outputs
terraform.tfvars          Your local values (don’t commit if it has secrets)
terraform.tfstate*        Terraform state (do NOT commit)
```

## Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

Upload an image to the source bucket to trigger the pipeline.

## Run Observability Stack

From `observability/`:

```bash
docker compose up -d
```
Endpoints:
- Grafana → http://<EC2-IP>:3000
- Prometheus → http://<EC2-IP>:9090
- Alertmanager → http://<EC2-IP>:9093

## Example PromQL Queries

Invocations (last 1 minute):


```bash
increase(aws_lambda_invocations_sum{dimension_FunctionName="image-processor-dev-processor"}[1m])
```

Errors:


```bash
increase(aws_lambda_errors_sum{dimension_FunctionName="image-processor-dev-processor"}[1m])
```

Duration (avg):


```bash
aws_lambda_duration_average{dimension_FunctionName="image-processor-dev-processor"}
```

## Alerts

Alert rules defined in:

```bash
observability/prometheus/rules/
```
Alertmanager configured to send email via SMTP (App Password required).

## Cleanup

```bash
docker compose down -v
terraform destroy
```

