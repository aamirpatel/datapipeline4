import json
import boto3
import os

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    bucket = os.environ['S3_BUCKET']
    key = 'input_data.json'  # Example key for S3 object

    try:
        # Read file from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        data = response['Body'].read().decode('utf-8')
        print(f"Data from S3: {data}")

        # Process the data (e.g., modify content)
        processed_data = data.upper()  # Example transformation
        
        # Write the processed data back to S3
        output_key = 'output_data.json'
        s3_client.put_object(Bucket=bucket, Key=output_key, Body=processed_data)

        return {
            'statusCode': 200,
            'body': json.dumps('Processing complete')
        }

    except Exception as e:
        print(f"Error processing S3 file: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Internal server error')
        }