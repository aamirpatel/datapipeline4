output "lambda_function_arn" {
  value = aws_lambda_function.data_processor.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.data_bucket.bucket
}
