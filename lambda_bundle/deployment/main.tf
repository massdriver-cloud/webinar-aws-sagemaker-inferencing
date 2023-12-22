locals {
  split_stage_name        = split("/", var.api_gateway.data.infrastructure.stage_arn)
  split_stage_name_length = length(local.split_stage_name)
  stage_name              = local.split_stage_name[local.split_stage_name_length - 1]
  api_id                  = split("/", var.api_gateway.data.infrastructure.arn)[2]
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = local.api_id
  stage_name  = local.stage_name

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_lambda_permission" "diffuser" {
#   statement_id  = "AllowDiffuserExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = var.md_metadata.name_prefix
#   principal     = "apigateway.amazonaws.com"

#   source_arn = "${aws_api_gateway_deployment.main.execution_arn}/${var.api.diffuser_http_method}/${var.api.diffuser_path}"
# }


resource "aws_lambda_permission" "llm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.md_metadata.name_prefix
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_deployment.main.execution_arn}/${var.api.llm_http_method}/${var.api.llm_path}"
}