# orders-infra

Terraform infrastructure for the [orders](https://github.com/leighwest/orders) cupcake ordering service, deployed on AWS in the `ap-southeast-4` (Melbourne) region.

---

## Architecture

```
GitHub Actions (push to main)
        ↓
Package Lambda zips → upload to S3 (by git SHA)
        ↓
Terraform apply
        ↓
AWS Infrastructure:
- EC2 (t3.small)
- Route 53: hosted zone + DNS records for leighwest.dev
- SQS: order-created, order-dispatched
- S3: cupcake images, deploy artefacts, lambda artifacts
- ECR: orders Docker image repository
- Lambda: dispatch service (Node.js), EC2 stop (Python)
- SES: transactional email
- IAM: instance role, Lambda roles, GitHub Actions user (least privilege)
- EventBridge: scheduled EC2 stop
- SSM Session Manager: bastion-free EC2 access
```

---

## Tech Stack

| Layer             | Technology                  |
| ----------------- | --------------------------- |
| IaC               | Terraform                   |
| Cloud             | AWS                         |
| CI/CD             | GitHub Actions              |
| State backend     | S3 (`orders-infra-tfstate`) |
| Runtime           | Amazon Linux 2023 / EC2     |
| Container runtime | Docker, Docker Compose      |

---

## CI/CD

Every push to `main` triggers the Terraform pipeline:

```
Push to main
     ↓
Package Lambda zips + upload to S3 (orders-lambda-artifacts, keyed by git SHA)
     ↓
terraform init (S3 backend)
     ↓
terraform fmt -check
     ↓
terraform validate
     ↓
terraform plan
     ↓
terraform apply -auto-approve
```

The pipeline is defined in `.github/workflows/terraform.yml`.

### Secrets required

| Secret                  | Description                   |
| ----------------------- | ----------------------------- |
| `AWS_ACCESS_KEY_ID`     | IAM credentials for Terraform |
| `AWS_SECRET_ACCESS_KEY` | IAM credentials               |
| `PERSONAL_IP_ADDRESS`   | Your IP in CIDR notation      |

---

## State Management

Terraform state is stored remotely in S3:

- **Bucket:** `orders-infra-tfstate`
- **Key:** `orders/terraform.tfstate`
- **Region:** `ap-southeast-4`
- **Versioning:** enabled

No DynamoDB lock — single developer workflow.

---

## Key Resources

| Resource                         | Description                                   |
| -------------------------------- | --------------------------------------------- |
| `aws_instance.orders`            | EC2 instance running the orders app           |
| `aws_route53_zone.leighwest_dev` | Hosted zone for leighwest.dev                 |
| `aws_sqs_queue.order_created`    | Orders publishes, Lambda consumes             |
| `aws_sqs_queue.order_dispatched` | Lambda publishes, orders consumes             |
| `aws_s3_bucket.orders`           | Stores cupcake images                         |
| `aws_s3_bucket.deploy`           | Stages deploy artefacts for SSM-based deploys |
| `aws_s3_bucket.lambda_artifacts` | Immutable Lambda zips keyed by git SHA        |
| `aws_ecr_repository.orders`      | Docker image repository                       |
| `aws_lambda_function.dispatch`   | Processes orders, publishes dispatch events   |
| `aws_lambda_function.ec2_stop`   | Scheduled stop of EC2 to save cost            |

---

## IAM Design

Separate roles per service — least privilege throughout:

| Principal                     | Type | Permissions                                                                                     |
| ----------------------------- | ---- | ----------------------------------------------------------------------------------------------- |
| `orders-ec2-instance-role`    | Role | SQS read/write, S3, ECR pull, SSM Parameter Store read, SSM Session Manager                     |
| `orders-github-actions`       | User | ECR push, EC2 start/describe, SSM send-command, S3 deploy + lambda buckets, Route 53, Terraform |
| `orders-dispatch-lambda-role` | Role | SQS consume order-created, SQS publish order-dispatched, CloudWatch logs                        |
| `lambda_execution_role`       | Role | EC2 start/stop, CloudWatch logs                                                                 |

No IAM users or access keys for the application — credentials come from the EC2 instance role.

---

## Secrets Management

Application secrets are stored in AWS Systems Manager Parameter Store:

| Parameter                  | Type         | Description         |
| -------------------------- | ------------ | ------------------- |
| `orders_mysql_password`    | SecureString | MySQL root password |
| `orders_ses_smtp_username` | String       | SES SMTP username   |
| `orders_ses_smtp_password` | SecureString | SES SMTP password   |

Secrets are fetched at deploy time by the `orders` pipeline — not stored in GitHub secrets.

---

## DNS

Route 53 is the authoritative DNS for `leighwest.dev` (domain registration remains at Namecheap).

**Nameservers (configured in Namecheap as custom DNS):**

```
ns-919.awsdns-50.net
ns-160.awsdns-20.com
ns-1500.awsdns-59.org
ns-2026.awsdns-61.co.uk
```

**Key records:**

| Record | Host               | TTL  | Notes                                           |
| ------ | ------------------ | ---- | ----------------------------------------------- |
| A      | `cupcakes-api`     | 60s  | Permanently low — supports fast DNS propagation |
| A      | `instance-starter` | 300s |                                                 |
| A      | `leighwest.dev`    | 300s | Netlify load balancer IPs                       |
| CNAME  | `www`              | 300s | Netlify                                         |
| CNAME  | `*._domainkey`     | 300s | SES DKIM (3 records)                            |
| TXT    | `_dmarc`           | 300s | DMARC policy                                    |

---

## Lambda Artifact Pattern

Lambda functions are deployed from S3, not from local zips. This is the standard pattern for deterministic, rollback-capable Lambda deployments.

The pipeline:

1. Packages `ec2_stop.py` and `dispatch_lambda/index.mjs` into zips
2. Uploads them to `orders-lambda-artifacts` keyed by `${{ github.sha }}`
3. Passes `GIT_SHA` to Terraform
4. Terraform deploys Lambdas pointing at the versioned S3 objects

This avoids the non-deterministic zip hashes produced by Terraform's `archive_file` data source when applied across different environments (local vs CI).

**Note:** For complex or frequently-changing Lambda functions, consider AWS SAM for local development and deployment. SAM provides local invocation (`sam local invoke`) without needing to deploy to AWS, and handles packaging independently of Terraform. Terraform would then manage only the Lambda infrastructure (IAM roles, triggers, queues) rather than code deployments.

---

## Local Usage

### Prerequisites

- Terraform installed
- AWS CLI configured with credentials for `ap-southeast-4`
- `terraform.tfvars` file (gitignored — see `terraform.tfvars.example`)

### Running locally

```bash
terraform init
terraform plan -var-file="terraform.tfvars" -var="GIT_SHA=$(git rev-parse HEAD)"
terraform apply -var-file="terraform.tfvars" -var="GIT_SHA=$(git rev-parse HEAD)"
```

Note: local apply requires Lambda zips to already exist in S3 for the current SHA. If applying locally after a Lambda code change, push to main first to let CI upload the zips, then apply locally.

---

## Key Design Decisions

| Decision                                 | Rationale                                                                                                                                                                              |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S3 backend (no DynamoDB lock)            | Remote state without overhead — single developer                                                                                                                                       |
| EC2 instance role                        | No credentials in config or Parameter Store for app auth                                                                                                                               |
| Separate IAM roles per Lambda            | Different trust boundaries and permission sets                                                                                                                                         |
| Direct Terraform resource refs           | Avoids hardcoded ARNs, creates implicit dependency ordering                                                                                                                            |
| Elastic IP                               | Stable public endpoint across EC2 stop/start cycles                                                                                                                                    |
| Scheduled EC2 stop                       | Cost saving — hobby project, instance not needed 24/7                                                                                                                                  |
| SSM Session Manager over SSH             | No open ports, IAM-controlled access, full audit trail in CloudWatch                                                                                                                   |
| S3 staging for deploy artefacts          | No SCP/SSH needed — runner uploads files, EC2 pulls them via instance role                                                                                                             |
| Scoped GitHub Actions IAM user           | Replaces broad AdministratorAccess with a named, version-controlled policy                                                                                                             |
| `aws_caller_identity` data source        | Replaces hardcoded account ID in ARNs — works across accounts without code changes                                                                                                     |
| Route 53 over Namecheap DNS              | Programmable API — enables Lambda-driven DNS updates on EC2 start without IP whitelisting constraints                                                                                  |
| S3 immutable artifact pattern for Lambda | Terraform's `archive_file` produces non-deterministic zips across environments. Pipeline builds once, uploads by SHA, Terraform deploys from S3 — clean separation of build and deploy |

---

## Related

- [orders](https://github.com/leighwest/orders) — Spring Boot application

---

## Versions

| Version                                                         | Description                                                                               |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [v1.0.0](https://github.com/leighwest/orders-infra/tree/v1.0.0) | t3.small + EIP, SSH access, AL2023, SQS + Lambda dispatch                                 |
| [v1.1.0](https://github.com/leighwest/orders-infra/tree/v1.1.0) | SSM Session Manager, scoped GitHub Actions IAM user, S3 deploy artefacts, port 22 removed |
