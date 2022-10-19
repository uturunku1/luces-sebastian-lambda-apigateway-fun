#
resource "random_pet" "lambda_bucket_name" {
  prefix = "luces-sebastian-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}


// This configuration uses the archive_file data source to generate a zip archive and an aws_s3_object resource to upload the archive to your S3 bucket.

data "archive_file" "lambda_params" {
  type = "zip" // Generates an archive from a file, or directory of files

  source_dir  = "${path.module}/params"
  output_path = "${path.module}/params.zip"
}

resource "aws_s3_object" "lambda_params" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "params.zip"
  source = data.archive_file.lambda_params.output_path

  etag = filemd5(data.archive_file.lambda_params.output_path)
}

resource "aws_lambda_function" "params" {
  function_name = "MyAPIGatewayParams"
    // configures the Lambda function to use the bucket object containing your function code 
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_params.key

  runtime = "nodejs12.x"
  handler = "params.handler" // assigns the handler to the handler function defined in params.js

  source_code_hash = data.archive_file.lambda_params.output_base64sha256 // The source_code_hash attribute will change whenever you update the code contained in the archive, which lets Lambda know that there is a new version of your code available

  role = aws_iam_role.lambda_exec.arn // specifies a role which grants the function permission to access AWS services and resources in your account.
}

// defines a log group to store log messages from your Lambda function for 30 days. By convention, Lambda stores logs in a group with the name /aws/lambda/<Function Name>.
resource "aws_cloudwatch_log_group" "params" {
  name = "/aws/lambda/${aws_lambda_function.params.function_name}"

  retention_in_days = 30
}

// defines an IAM role that allows Lambda to access resources in your AWS account.
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

// attaches a policy the IAM role. The AWSLambdaBasicExecutionRole is an AWS managed policy that allows your Lambda function to write to CloudWatch logs.
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// local cmds we can run to check state of things if we don't feel like showing the aws console:
// aws s3 ls $(terraform output -raw lambda_bucket_name)
// aws lambda invoke --region=us-east-1 --function-name=$(terraform output -raw function_name) response.json
// cat response.json
