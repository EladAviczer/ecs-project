data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name           = "${var.cluster_name}-vpc"
  cidr           = "10.0.0.0/16"
  azs            = ["euc1-az1", "euc1-az2"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  #   enable_nat_gateway      = true
  #   single_nat_gateway      = true
  #   enable_dns_hostnames    = true
  #   map_public_ip_on_launch = true
}
