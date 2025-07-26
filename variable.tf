variable "vpc_azs" {
    type = list
    default = ["us-east-1a", "us-east-2"]
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_subnets" {
  type = map
  default = {
    public1 = ["10.0.0.0/24", "us-east-1a"]
    public2 = ["10.0.1.0/24", "us-east-1b"]
    private = ["10.0.80.0/24", "us-east-1a"]
    isolated1 = ["10.0.160.0/24", "us-east-1a"]
    isolated2 = ["10.0.161.0/24", "us-east-1b"]
  }
}

variable "branch" {
    default = "dev"
}