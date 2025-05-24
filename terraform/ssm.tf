resource "aws_ssm_parameter" "token" {
  name  = var.ssm_parameter_name
  type  = "String"
  value = var.ssm_parameter_value
}
