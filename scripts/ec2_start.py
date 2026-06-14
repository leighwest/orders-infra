import boto3
import urllib.request
import urllib.error
import time
import os
import json

region = os.environ['REGION']
kvs_arn = os.environ['KVS_ARN']
CF_API_TOKEN = os.environ['CF_API_TOKEN']
CF_ZONE_ID = os.environ['CF_ZONE_ID']
CF_RECORD_ID = os.environ['CF_RECORD_ID'] 

ec2 = boto3.client('ec2', region_name=region)
kvs = boto3.client('cloudfront-keyvaluestore')

def set_kvs_state(value):
    try:
        response = kvs.get_key(KvsARN=kvs_arn, Key='ec2_state')
        etag = response['ETag']
    except Exception:
        kvs_info = kvs.describe_key_value_store(KvsARN=kvs_arn)
        etag = kvs_info['ETag']

    kvs.put_key(KvsARN=kvs_arn, Key='ec2_state', Value=value, IfMatch=etag)
    print(f'KVS flag set to {value}')

def update_cloudflare_dns(ip):
    url = f'https://api.cloudflare.com/client/v4/zones/{CF_ZONE_ID}/dns_records/{CF_RECORD_ID}'
    payload = json.dumps({
        'type': 'A',
        'name': 'origin.cupcakes-api.leighwest.dev',
        'content': ip,
        'ttl': 60,
        'proxied': False
    }).encode('utf-8')

    req = urllib.request.Request(
        url,
        data=payload,
        method='PUT',
        headers={
            'Authorization': f'Bearer {CF_API_TOKEN}',
            'Content-Type': 'application/json'
        }
    )

    with urllib.request.urlopen(req) as r:
        body = json.loads(r.read())
        if not body.get('success'):
            raise Exception(f'Cloudflare DNS update failed: {body.get("errors")}')
        print(f'origin DNS updated to {ip} via Cloudflare')

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

    response = ec2.describe_instances(InstanceIds=[instance_id])
    public_ip = response['Reservations'][0]['Instances'][0]['PublicIpAddress']
    print('Public IP: ' + public_ip)

    update_cloudflare_dns(public_ip)

    health_url = 'http://' + public_ip + ':80/actuator/health'
    for attempt in range(24):
        try:
            with urllib.request.urlopen(health_url, timeout=5) as r:
                if r.status == 200:
                    print('App is healthy')
                    set_kvs_state('up')
                    break
        except Exception as e:
            print(f'Health check attempt {attempt + 1} failed: {e}')
        time.sleep(5)
    else:
        print('App did not become healthy in time')