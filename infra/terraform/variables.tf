variable "region" {
  default = "us-east-1"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI id for your region"
}

variable "instance_type" {
  default = "t3.large"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH"
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH (lock this down to your IP)"
  default     = "0.0.0.0/0"
}
