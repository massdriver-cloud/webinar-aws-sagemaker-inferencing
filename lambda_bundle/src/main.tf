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
### Diffusers Block ###
resource "aws_api_gateway_resource" "diffuser" {
  rest_api_id = local.api_id
  parent_id   = var.api_gateway.data.infrastructure.root_resource_id
  path_part   = var.api.diffuser_path
}

resource "aws_api_gateway_method" "diffuser" {
  rest_api_id   = local.api_id
  resource_id   = aws_api_gateway_resource.diffuser.id
  http_method   = var.api.diffuser_http_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "diffuser" {
  rest_api_id             = local.api_id
  resource_id             = aws_api_gateway_resource.diffuser.id
  http_method             = aws_api_gateway_method.diffuser.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_application.function_invoke_arn
}

resource "aws_iam_policy_attachment" "attach_diffuser_invoke_policy" {
  name      = "attach_diffuser_invoke_policy"
  roles      = [local.role_name]
  policy_arn = var.diffuser_endpoint.data.security.iam.invoke.policy_arn
}

### Diffusers Block End###


### LLM Block ###
resource "aws_api_gateway_resource" "llm" {
  rest_api_id = local.api_id
  parent_id   = var.api_gateway.data.infrastructure.root_resource_id
  path_part   = var.api.llm_path
}

resource "aws_api_gateway_method" "llm" {
  rest_api_id   = local.api_id
  resource_id   = aws_api_gateway_resource.llm.id
  http_method   = var.api.llm_http_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "llm" {
  rest_api_id             = local.api_id
  resource_id             = aws_api_gateway_resource.llm.id
  http_method             = aws_api_gateway_method.llm.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_application.function_invoke_arn
}

resource "aws_iam_policy_attachment" "attach_llm_invoke_policy" {
  name      = "attach_llm_invoke_policy"
  roles      = [local.role_name]
  policy_arn = var.llm_endpoint.data.security.iam.invoke.policy_arn
}


### LLM Block End###