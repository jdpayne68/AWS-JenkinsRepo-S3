#Define the AWS region where resources will be created
variable "region" {
  description = "AWS region to deploy resources"
  default = "us-east-1"
}

# core VPC paramters 
variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  default = "192.0.0.0/16"
}

variable "subnet_cidr_blocks" {

  description = "CIDR blocks for all subnets by name"
  type = object({
    private-us-east-1a = string
    public-us-east-1a = string
    
  })
  default = {
    private-us-east-1a = "192.0.0.0/24"
    public-us-east-1a = "192.0.64.0/24"
  }
}
variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.medium"
}
