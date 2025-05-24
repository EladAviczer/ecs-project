variable "region" {
  default = "us-west-1"
}
variable "cluster_name" {
  default = "eladik"
}
variable "queue_name" {
  default   = "eladik"
  sensitive = true
}
variable "image1name" {
  default = "ms1:latest"
}
variable "image2name" {
  default = "ms2:latest"
}
variable "alb_name" {
  default = "eladik-alb"
}
variable "ssm_parameter_name" {
  default = "eladik-parameter"
}
variable "ssm_parameter_value" {
  sensitive = true
  default   = "zor"

}
