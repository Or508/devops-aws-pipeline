variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_key_name" {
  description = "Existing AWS EC2 Key Pair name (must match Jenkins credential ssh-key-id for user ubuntu)"
  type        = string

  validation {
    condition     = length(trimspace(var.aws_key_name)) > 0
    error_message = "aws_key_name must be a non-empty Key Pair name registered in AWS."
  }
}

variable "project_name" {
  description = "Prefix for resource naming"
  type        = string
  default     = "redux-movie-app"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the instance (restrict in production)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
  default     = "production"
}

variable "ansible_ssh_user" {
  description = "SSH user for Ansible (Ubuntu default)"
  type        = string
  default     = "ubuntu"
}

variable "ansible_inventory_path" {
  description = "Path to generated Ansible inventory file (relative to repo root)"
  type        = string
  default     = "../ansible/inventory/inventory.ini"
}
