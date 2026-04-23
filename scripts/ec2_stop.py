import boto3
import os

region = os.environ['REGION']
instance_id = os.environ['INSTANCE_ID']
ec2 = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    ec2.stop_instances(InstanceIds=[instance_id])
    print('Stopped your instance: ' + instance_id)
