data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "obs_sg" {
  name        = "${var.name}-obs-sg"
  description = "Security group for Prometheus/Grafana/Alertmanager host"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  # Grafana
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  # Prometheus UI (optional but enabled for now)
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  # Alertmanager UI (optional but enabled for now)
  ingress {
    description = "Alertmanager"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  # YACE exporter (keep private later; open now for simplicity)
  ingress {
    description = "YACE"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-obs-sg"
  })
}

resource "aws_instance" "obs" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.obs_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  iam_instance_profile = aws_iam_instance_profile.obs_profile.name
  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
  assets_bucket = var.assets_bucket
  assets_key    = var.assets_key
  })
  root_block_device {
  volume_size = 30
  volume_type = "gp3"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-observability"
  })
}

resource "aws_iam_role" "obs_role" {
  name = "${var.name}-obs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "obs_profile" {
  name = "${var.name}-obs-profile"
  role = aws_iam_role.obs_role.name
}

# Policy attached later in Step 4 for CloudWatch read (YACE).
# For Step 3 we only need S3 read to fetch observability.zip.
resource "aws_iam_role_policy" "s3_read_assets" {
  name = "${var.name}-obs-s3-read"
  role = aws_iam_role.obs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["s3:GetObject"],
      Resource = [
        "arn:aws:s3:::${var.assets_bucket}/${var.assets_key}"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "yace_read_cloudwatch" {
  name = "${var.name}-obs-yace-read"
  role = aws_iam_role.obs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "tag:GetResources"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:ListAccountAliases"
        ],
        Resource = "*"
      }
    ]
  })
}