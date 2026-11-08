data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_instance" "automation" {
  ami                         = data.aws_ssm_parameter.ubuntu.value
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.ec2_security_group_id]
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    set -e

    if ! snap list amazon-ssm-agent >/dev/null 2>&1; then
        snap install amazon-ssm-agent --classic
    fi

    snap start amazon-ssm-agent
  EOF

  iam_instance_profile = aws_iam_instance_profile.automation.name


  tags = {
    Name        = "${var.project_name}-${var.environment}-automation"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

}

resource "aws_iam_role" "automation" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.automation.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "automation" {
  name = "${var.project_name}-${var.environment}-instance-profile"
  role = aws_iam_role.automation.name
}