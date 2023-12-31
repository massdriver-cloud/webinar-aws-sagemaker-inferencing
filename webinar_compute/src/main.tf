locals {
  api_id = split("/", var.api_gateway.data.infrastructure.arn)[2]
  split_role = split("/", module.lambda_application.identity)
  role_name = element(local.split_role, length(local.split_role) - 1)
}

module "lambda_application" {
  source            = "github.com/massdriver-cloud/terraform-modules//massdriver-application-aws-lambda?ref=23a47fa"
  md_metadata       = var.md_metadata
  image             = var.runtime.image
  x_ray_enabled     = var.observability.x-ray.enabled
  retention_days    = var.observability.retention_days
  memory_size       = var.runtime.memory_size
  execution_timeout = var.runtime.execution_timeout
}

resource "aws_api_gateway_resource" "main" {
  rest_api_id = local.api_id
  parent_id   = var.api_gateway.data.infrastructure.root_resource_id
  path_part   = var.api.path
}

resource "aws_api_gateway_method" "main" {
  rest_api_id   = local.api_id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = var.api.http_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "main" {
  rest_api_id             = local.api_id
  resource_id             = aws_api_gateway_resource.main.id
  http_method             = aws_api_gateway_method.main.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_application.function_invoke_arn
}

resource "aws_api_gateway_resource" "mistral" {
  rest_api_id = local.api_id
  parent_id   = var.api_gateway.data.infrastructure.root_resource_id
  path_part   = var.api.path_2
}

resource "aws_api_gateway_method" "mistral" {
  rest_api_id   = local.api_id
  resource_id   = aws_api_gateway_resource.mistral.id
  http_method   = var.api.http_method_2
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "mistral" {
  rest_api_id             = local.api_id
  resource_id             = aws_api_gateway_resource.mistral.id
  http_method             = aws_api_gateway_method.mistral.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_application.function_invoke_arn
}

resource "aws_iam_policy_attachment" "attach_s3_read_policy" {
  name      = "attach_s3_read_policy"
  roles      = [local.role_name]
  policy_arn = var.webinar_bucket.data.security.iam.read.policy_arn
}


resource "aws_iam_policy_attachment" "attach_s3_write_policy" {
  name     = "attach_s3_write_policy"
  roles      = [local.role_name]
  policy_arn = var.webinar_bucket.data.security.iam.write.policy_arn
}

resource "aws_iam_policy_attachment" "attach_sdxl_invoke_policy" {
  name      = "attach_sdxl_invoke_policy"
  roles      = [local.role_name]
  policy_arn = var.sdxl_endpoint.data.security.iam.invoke.policy_arn
}

resource "aws_iam_policy_attachment" "attach_llm_invoke_policy" {
  name      = "attach_llm_invoke_policy"
  roles      = [local.role_name]
  policy_arn = var.llm_endpoint.data.security.iam.invoke.policy_arn
}