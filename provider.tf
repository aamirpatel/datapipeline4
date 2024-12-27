provider "aws" {
  region = "us-east-1"  # or your preferred AWS region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.18.0"
    }
  }
  backend "s3" {
    bucket         = "myaptestbucketstate"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "mystate"
  }
}



resource "aws_s3_bucket" "data_bucket" {
  bucket = "my-data-pipeline-bucket-71189"
}
resource "aws_s3_bucket_ownership_controls" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "data_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.data_bucket]

  bucket = aws_s3_bucket.data_bucket.id
  acl    = "private"
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
  role_arn = "arn:aws:iam::985539789378:role/AWSGlueServiceRole"
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
