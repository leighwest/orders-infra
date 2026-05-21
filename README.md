# orders-infra

Terraform infrastructure for the [orders](https://github.com/leighwest/orders) cupcake ordering service, deployed on AWS in the `ap-southeast-4` (Melbourne) region.

---

## Architecture

```
GitHub Actions (push to main)
        ↓
Terraform apply
        ↓
AWS Infrastructure:
- EC2 (t3.small)
- SQS: order-created, order-dispatched
- S3: cupcake images, deploy artefacts
- ECR: orders Docker image repository
- Lambda: dispatch service (Node.js)
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
| `aws_eip.orders-eip`             | Elastic IP — persists across stop/start       |
| `aws_sqs_queue.order_created`    | Orders publishes, Lambda consumes             |
| `aws_sqs_queue.order_dispatched` | Lambda publishes, orders consumes             |
| `aws_s3_bucket.orders`           | Stores cupcake images                         |
| `aws_s3_bucket.deploy`           | Stages deploy artefacts for SSM-based deploys |
| `aws_ecr_repository.orders`      | Docker image repository                       |
| `aws_lambda_function.dispatch`   | Processes orders, publishes dispatch events   |
| `aws_lambda_function.ec2_stop`   | Scheduled stop of EC2 to save cost            |

---

## IAM Design

Separate roles per service — least privilege throughout:

| Principal                     | Type | Permissions                                                                 |
| ----------------------------- | ---- | --------------------------------------------------------------------------- |
| `orders-ec2-instance-role`    | Role | SQS read/write, S3, ECR pull, SSM Parameter Store read, SSM Session Manager |
| `orders-github-actions`       | User | ECR push, EC2 start/describe, SSM send-command, S3 deploy bucket, Terraform |
| `orders-dispatch-lambda-role` | Role | SQS consume order-created, SQS publish order-dispatched, CloudWatch logs    |
| `lambda_execution_role`       | Role | EC2 start/stop, CloudWatch logs                                             |

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

## Local Usage

### Prerequisites

- Terraform installed
- AWS CLI configured with credentials for `ap-southeast-4`
- `terraform.tfvars` file (gitignored — see `terraform.tfvars.example`)

### Running locally

```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

---

## Key Design Decisions

| Decision                          | Rationale                                                                                                                        |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| S3 backend (no DynamoDB lock)     | Remote state without overhead — single developer                                                                                 |
| EC2 instance role                 | No credentials in config or Parameter Store for app auth                                                                         |
| Separate IAM roles per Lambda     | Different trust boundaries and permission sets                                                                                   |
| Direct Terraform resource refs    | Avoids hardcoded ARNs, creates implicit dependency ordering                                                                      |
| Elastic IP                        | Stable public endpoint across EC2 stop/start cycles                                                                              |
| Scheduled EC2 stop                | Cost saving — hobby project, instance not needed 24/7                                                                            |
| SSM Session Manager over SSH      | No open ports, IAM-controlled access, full audit trail in CloudWatch — enterprise standard for bastion-free EC2 access           |
| S3 staging for deploy artefacts   | No SCP/SSH needed — runner uploads files, EC2 pulls them via instance role. Standard pattern alongside SSM send-command          |
| Scoped GitHub Actions IAM user    | Replaces broad AdministratorAccess with a named, version-controlled policy. OIDC federation would be the next step in production |
| `aws_caller_identity` data source | Replaces hardcoded account ID in ARNs — works across accounts without code changes                                               |

---

## Related

- [orders](https://github.com/leighwest/orders) — Spring Boot application

---

## Versions

| Version                                                         | Description                                                                               |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [v1.0.0](https://github.com/leighwest/orders-infra/tree/v1.0.0) | t3.small + EIP, SSH access, AL2023, SQS + Lambda dispatch                                 |
| [v1.1.0](https://github.com/leighwest/orders-infra/tree/v1.1.0) | SSM Session Manager, scoped GitHub Actions IAM user, S3 deploy artefacts, port 22 removed |
| [v2.0.0](https://github.com/leighwest/orders-infra/tree/v2.0.0) | TBD                                                                                       |
