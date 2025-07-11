variable "region" {
  default = "us-east-1"
}

# core VPC paramters 
variable "vpc_cidr" {
  default = "192.0.0.0/16"
}

variable "subnet_cidr_blocks" {
  description = "CIDR blocks for all subnets by name"
  type = object({
    private-us-east-1a = string
    #private-us-east-1b = string
    public-us-east-1a  = string
    #public-us-east-1b  = string
  })
  default = {
    private-us-east-1a = "192.0.0.0/24"
    #private-us-east-1b = "192.0.32.0/24"
    public-us-east-1a  = "192.0.64.0/24"
    #public-us-east-1b  = "192.0.96.0/24"
  }
}

variable "key_name" {
  description = "The name of the key pair"
  default     = "jenkins-key"
}

variable "public_key_path" {
  description = "Path to your public SSH key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.medium"
}
