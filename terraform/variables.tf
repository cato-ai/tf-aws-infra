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
  default     = "ami-02b949400f3236da8"
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


