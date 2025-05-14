packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "source_ami" {
  default = "ami-0f9de6e2d2f067fca"
}

variable "instance_type" {
  default = "t2.medium"
}

source "amazon-ebs" "jenkins" {
  region                      = var.aws_region
  source_ami                  = var.source_ami
  instance_type               = var.instance_type
  ssh_username                = "ubuntu"
  ami_name                    = "jenkins-ami-{{timestamp}}"
  associate_public_ip_address = true
  communicator                = "ssh"
}

build {
  name = "jenkins-ami"

  sources = [
    "source.amazon-ebs.jenkins"
  ]

  provisioner "file" {
    source      = "setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh"
    ]
  }
}
