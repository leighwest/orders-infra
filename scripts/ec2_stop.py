import boto3
import os

region = os.environ['REGION']
kvs_arn = os.environ['KVS_ARN']

ec2 = boto3.client('ec2', region_name=region)
kvs = boto3.client('cloudfront-keyvaluestore')

def set_kvs_state(value):
    try:
        response = kvs.get_key(KvsARN=kvs_arn, Key='ec2_state')
        etag = response['ETag']
    except kvs.exceptions.ResourceNotFoundException:
        etag = None

    if etag:
        kvs.put_key(KvsARN=kvs_arn, Key='ec2_state', Value=value, IfMatch=etag)
    else:
        kvs.put_key(KvsARN=kvs_arn, Key='ec2_state', Value=value)
    print(f'KVS flag set to {value}')

def lambda_handler(event, context):
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Name', 'Values': ['orders-server']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )

    instances = response['Reservations']
    if not instances:
        raise Exception('No running instance found with tag Name=orders-server')

    instance_id = instances[0]['Instances'][0]['InstanceId']

    # Write flag before stopping — Lambda@Edge serves closed page immediately
    set_kvs_state('down')

    ec2.stop_instances(InstanceIds=[instance_id])
    print('Stopped instance: ' + instance_id)