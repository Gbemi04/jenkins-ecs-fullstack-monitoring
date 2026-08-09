# ============================================================
# Jenkins EC2 Server
# ============================================================

# Get the latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ============================================================
# Jenkins Security Group
# ============================================================

resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-${var.environment}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.main.id

  # SSH access only from administrator IP
  ingress {
    description = "SSH from administrator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.jenkins_admin_cidr]
  }

  # Jenkins web interface only from administrator IP
  ingress {
    description = "Jenkins UI from administrator"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.jenkins_admin_cidr]
  }

  # Allow Jenkins to reach GitHub, AWS APIs, package repositories, etc.
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}


# ============================================================
# Jenkins EC2 Instance
# ============================================================

resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"

  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  associate_public_ip_address = true

  key_name = "aws"

  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  # Recreate EC2 automatically if the startup script changes
  user_data_replace_on_change = true

  user_data = <<EOF
#!/bin/bash
set -e

# ============================================================
# Update Ubuntu packages
# ============================================================

apt-get update


# ============================================================
# Install base packages
# ============================================================

apt-get install -y \
fontconfig \
openjdk-21-jre \
git \
docker.io \
unzip \
curl \
wget \
gpg \
lsb-release


# ============================================================
# Install Jenkins
# ============================================================

install -m 0755 -d /etc/apt/keyrings

wget -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
> /etc/apt/sources.list.d/jenkins.list

apt-get update

apt-get install -y jenkins


# ============================================================
# Configure Docker
# ============================================================

systemctl enable --now docker

usermod -aG docker ubuntu
usermod -aG docker jenkins


# ============================================================
# Install AWS CLI v2
# ============================================================

cd /tmp

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
-o awscliv2.zip

unzip -q awscliv2.zip

./aws/install


# ============================================================
# Install Terraform
# ============================================================

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
> /etc/apt/sources.list.d/hashicorp.list

apt-get update

apt-get install -y terraform


# ============================================================
# Start Jenkins
# ============================================================

systemctl enable jenkins
systemctl restart jenkins
EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins"
    Environment = var.environment
    Project     = var.project_name
  }
}