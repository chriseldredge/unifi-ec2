variable "aws_access_key" {
  description = "The AWS access key."
}

variable "aws_secret_key" {
  description = "The AWS secret key."
}

variable "region" {
  description = "The AWS region to create resources in."
  default = "us-east-1"
}

variable "availability_zone" {
  description = "The availability zone"
  default = "us-east-1d"
}

variable "key_pair_name" {
  description = "Name of key pair"
}
variable "ssh_pubkey_file" {
  description = "Path to an SSH public key"
}

variable "ami" {
  description = "Which AMI to spawn."
  default = "ami-0ac80df6eff0e70b5"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "server_name" {
  description = "FQDN for certbot/nginx config"
}

variable "admin_email" {
  description = "Email address for letsencrypt certbot"
}
