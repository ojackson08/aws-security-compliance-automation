import json
import boto3
import os

s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
topic_arn = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    print(f"Received EventBridge event: {json.dumps(event)}")
    
    # Check if this is an AWS Config compliance change event
    if event.get('source') == 'aws.config':
        detail = event.get('detail', {})
        new_status = detail.get('newEvaluationResult', {}).get('complianceType')
        resource_type = detail.get('resourceType')
        resource_id = detail.get('resourceId') # This is the bucket name
        
        # We are looking for S3 buckets that became NON_COMPLIANT
        if resource_type == 'AWS::S3::Bucket' and new_status == 'NON_COMPLIANT':
            print(f"Non-compliant S3 bucket detected: {resource_id}. Attempting remediation...")
            
            try:
                # 1. Block Public Access
                s3_client.put_public_access_block(
                    Bucket=resource_id,
                    PublicAccessBlockConfiguration={
                        'BlockPublicAcls': True,
                        'IgnorePublicAcls': True,
                        'BlockPublicPolicy': True,
                        'RestrictPublicBuckets': True
                    }
                )
                print(f"Successfully blocked public access for bucket {resource_id}")
                
                # 2. Enable Default Encryption
                s3_client.put_bucket_encryption(
                    Bucket=resource_id,
                    ServerSideEncryptionConfiguration={
                        'Rules': [
                            {
                                'ApplyServerSideEncryptionByDefault': {
                                    'SSEAlgorithm': 'AES256'
                                },
                                'BucketKeyEnabled': True
                            }
                        ]
                    }
                )
                print(f"Successfully enabled default encryption for bucket {resource_id}")
                
                # 3. Notify Security Team
                message = f"SECURITY ALERT REMEDIATED:\n\nBucket: {resource_id}\nAction Taken: Blocked public access and enabled AES256 encryption.\nTrigger: AWS Config compliance rule violation."
                sns_client.publish(
                    TopicArn=topic_arn,
                    Subject=f"AWS Security Auto-Remediation: {resource_id}",
                    Message=message
                )
                
                return {
                    'statusCode': 200,
                    'body': json.dumps(f"Remediation successful for {resource_id}")
                }
                
            except Exception as e:
                error_msg = f"Failed to remediate bucket {resource_id}. Error: {str(e)}"
                print(error_msg)
                
                # Notify of failure
                sns_client.publish(
                    TopicArn=topic_arn,
                    Subject=f"URGENT: Auto-Remediation FAILED for {resource_id}",
                    Message=error_msg
                )
                
                return {
                    'statusCode': 500,
                    'body': json.dumps(error_msg)
                }
                
    return {
        'statusCode': 200,
        'body': json.dumps("Event processed, no remediation required.")
    }
