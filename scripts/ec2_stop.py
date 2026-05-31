import boto3
import os

region = os.environ['REGION']
HOSTED_ZONE_ID = os.environ['HOSTED_ZONE_ID']
CLOUDFRONT_DOMAIN = os.environ['CLOUDFRONT_DOMAIN']

ec2 = boto3.client('ec2', region_name=region)
route53 = boto3.client('route53')

def lambda_handler(event, context):
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Name', 'Values': ['orders-server']}
        ]
    )

    instances = response['Reservations']
    if not instances:
        raise Exception('No matching instance found')

    instance_id = instances[0]['Instances'][0]['InstanceId']

    # Flip DNS to CloudFront before stopping
    route53.change_resource_record_sets(
        HostedZoneId=HOSTED_ZONE_ID,
        ChangeBatch={
            'Changes': [{
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': 'cupcakes-api.leighwest.dev',
                    'Type': 'A',
                    'AliasTarget': {
                        'HostedZoneId': 'Z2FDTNDATAQYW2',
                        'DNSName': CLOUDFRONT_DOMAIN,
                        'EvaluateTargetHealth': False
                    }
                }
            }]
        }
    )
    print('DNS flipped to CloudFront: ' + CLOUDFRONT_DOMAIN)

    # Stop instance
    ec2.stop_instances(InstanceIds=[instance_id])
    print('Stopped instance: ' + instance_id)



