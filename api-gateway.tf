// defines a name for the API Gateway and sets its protocol to HTTP
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

// sets up application stages for the API Gateway - such as "Test", "Staging", and "Production". The example configuration defines a single stage, with access logging enabled.
resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}
// configures the API Gateway to use your Lambda function
resource "aws_apigatewayv2_integration" "params" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.params.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}
// maps an HTTP request to a target, in this case your Lambda function. In the example configuration, the route_key matches any GET request matching the path /params. A target matching integrations/<ID> maps to a Lambda integration with the given ID
resource "aws_apigatewayv2_route" "params" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /params"
  target    = "integrations/${aws_apigatewayv2_integration.params.id}"
}
// defines a log group to store access logs for the aws_apigatewayv2_stage.lambda API Gateway stage.
resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}
// gives API Gateway permission to invoke your Lambda function.
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.params.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

// send a request to API Gateway to invoke the Lambda function. The endpoint consists of the base_url output value + the /params path (defined as the route_key above) + include Name query parameter
// curl "$(terraform output -raw base_url)/params?Name=luces"

// let's not forget to "terraform destroy" at the end!