variable "subnet_0_az" {
  type        = string
  default     = "us-east-1a"
  description = "Subnet Availability Zone - 0"
}

variable "subnet_1_az" {
  type        = string
  default     = "us-east-1b"
  description = "Subnet Availability Zone - 1"
}

variable "subnet_2_az" {
  type        = string
  default     = "us-east-1c"
  description = "Subnet Availability Zone - 2"
}

variable "provider_region" {
  type        = string
  default     = "us-east-1"
  description = "Region location for aws"
}

variable "vpc_ip" {
  type        = string
  default     = "10.10.0.0/16"
  description = "IP for VPC"
}

variable "ami_name" {
  description = "The name of the AMI to be used for the EC2 instance"
  type        = string
  default     = "ami-0707640677e9a9e1f"
}

variable "volume_size" {
  description = "The size of volume in (GiB)"
  type        = number
  default     = 25
}

variable "key_name" {
  description = "The Key used to create instance"
  type        = string
  default     = ""
}

variable "DB_USERNAME" {
  description = "Default name of DB User"
  type        = string
  default     = "cato_ai"
  sensitive   = true
}

variable "DB_PASSWORD" {
  description = "Default password of DB User"
  type        = string
  default     = ""
  sensitive   = true
}

variable "DB_NAME" {
  description = "Default name of DB "
  type        = string
  default     = "c4t0"
  sensitive   = true
}

variable "SERVER_HOSTNAME" {
  description = "Default hostname of application "
  type        = string
  default     = "127.0.0.1"
  sensitive   = true
}

variable "SERVER_PORT_NUMBER" {
  description = "Default hostname of application "
  type        = string
  default     = "3000"
  sensitive   = true

}