variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.124.0.0/16"
}

variable "access_ip" {
  description = "The IP address allowed to access the resources"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "The type of instance to use for the web server"
  type        = string
  default     = "t3.micro"
}

variable "main_instance_count" {
  description = "Number of main instances to launch"
  type        = number
  default     = 1
}

variable "key_name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
  default     = "deployer-key"
}