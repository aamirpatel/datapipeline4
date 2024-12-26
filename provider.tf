provider "aws" {
  region = "us-east-1"  # or your preferred AWS region
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "my-data-pipeline-bucket"
  aws_s3_bucket_acl    = "private"
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "lambda.amazonaws.com" }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

resource "aws_lambda_function" "data_processor" {
  function_name = "DataProcessor"
  role          = "arn:aws:iam::985539789378:role/AWSGlueServiceRole"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  
  # Path to your zipped Lambda function code
  filename      = "lambda/lambda.zip"
  source_code_hash = filebase64sha256("lambda/lambda.zip")
  
  environment {
    variables = {
      "S3_BUCKET" = aws_s3_bucket.data_bucket.bucket
    }
  }
}

resource "aws_glue_catalog_database" "data_catalog" {
  name = "my_data_catalog"
}

resource "aws_glue_job" "data_transform_job" {
  name     = "data-transform-job"
  role     = "arn:aws:iam::985539789378:role/AWSGlueServiceRole"
  command {
    name            = "glueetl"
    script_location = "s3://my-scripts-bucket/my-script.py"
  }
  max_capacity = 10
}

resource "aws_s3_object" "lambda_script" {
  bucket = aws_s3_bucket.data_bucket.bucket
  key    = "scripts/my_script.py"
  source = "scripts/my_script.py"  # Local path to your Glue script
}
