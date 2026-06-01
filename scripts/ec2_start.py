import boto3
import urllib.request
import time
import os

region = os.environ['REGION']
HOSTED_ZONE_ID = os.environ['HOSTED_ZONE_ID']

ec2 = boto3.client('ec2', region_name=region)
route53 = boto3.client('route53')

def lambda_handler(event, context):
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Name', 'Values': ['orders-server']},
            {'Name': 'instance-state-name', 'Values': ['stopped', 'running', 'pending']}
        ]
    )

    instances = response['Reservations']
    if not instances:
        raise Exception('No active instance found with tag Name=orders-server')

    instance = instances[0]['Instances'][0]
    instance_id = instance['InstanceId']
    instance_state = instance['State']['Name']

    if instance_state == 'stopped':
        ec2.start_instances(InstanceIds=[instance_id])
        print('Started instance: ' + instance_id)

        waiter = ec2.get_waiter('instance_status_ok')
        waiter.wait(InstanceIds=[instance_id])
        print('Instance status OK')
    else:
        print('Instance already running, skipping start')

    # Always update DNS regardless of instance state
    response = ec2.describe_instances(InstanceIds=[instance_id])
    public_ip = response['Reservations'][0]['Instances'][0]['PublicIpAddress']
    print('Public IP: ' + public_ip)

    route53.change_resource_record_sets(
        HostedZoneId=HOSTED_ZONE_ID,
        ChangeBatch={
            'Changes': [{
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': 'origin.cupcakes-api.leighwest.dev',
                    'Type': 'A',
                    'TTL': 60,
                    'ResourceRecords': [{'Value': public_ip}]
                }
            }]
        }
    )
    print('origin DNS updated to ' + public_ip)

    health_url = 'http://' + public_ip + ':80/actuator/health'
    for attempt in range(24):  # 2 min max (24 * 5s)
        try:
            with urllib.request.urlopen(health_url, timeout=5) as r:
                if r.status == 200:
                    print('App is healthy')
                    break
        except Exception as e:
            print(f'Health check attempt {attempt + 1} failed: {e}')
        time.sleep(5)
    else:
        print('App did not become healthy in time')