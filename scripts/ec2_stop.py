import boto3
import os

region = os.environ['REGION']
ec2 = boto3.client('ec2', region_name=region)

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
    ec2.stop_instances(InstanceIds=[instance_id])
    print('Stopped instance: ' + instance_id)



