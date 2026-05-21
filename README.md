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
- EC2 (t3.small) + Elastic IP
- SQS: order-created, order-dispatched
- S3: cupcake images
- ECR: orders Docker image repository
- Lambda: dispatch service (Node.js)
- SES: transactional email
- IAM: instance role, Lambda roles (least privilege)
- EventBridge: scheduled EC2 stop
```

---

## Tech Stack

| Layer             | Technology                  |
| ----------------- | --------------------------- |
| IaC               | Terraform                   |
| Cloud             | AWS                         |
| CI/CD             | GitHub Actions              |
| State backend     | S3 (`orders-infra-tfstate`) |
| Runtime           | Amazon Linux 2 / EC2        |
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

| Secret                  | Description                                                    |
| ----------------------- | -------------------------------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | IAM credentials for Terraform                                  |
| `AWS_SECRET_ACCESS_KEY` | IAM credentials                                                |
| `PERSONAL_IP_ADDRESS`   | Your IP in CIDR notation — used to restrict SSH access locally |
| `INSTANCE_ID`           | EC2 instance ID                                                |

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

| Resource                         | Description                                 |
| -------------------------------- | ------------------------------------------- |
| `aws_instance.orders`            | EC2 instance running the orders app         |
| `aws_eip.orders-eip`             | Elastic IP — persists across stop/start     |
| `aws_sqs_queue.order_created`    | Orders publishes, Lambda consumes           |
| `aws_sqs_queue.order_dispatched` | Lambda publishes, orders consumes           |
| `aws_s3_bucket.orders`           | Stores cupcake images                       |
| `aws_ecr_repository.orders`      | Docker image repository                     |
| `aws_lambda_function.dispatch`   | Processes orders, publishes dispatch events |
| `aws_lambda_function.ec2_stop`   | Scheduled stop of EC2 to save cost          |

---

## IAM Design

Separate roles per service — least privilege throughout:

| Role                          | Used by         | Permissions                                                              |
| ----------------------------- | --------------- | ------------------------------------------------------------------------ |
| `orders-ec2-instance-role`    | EC2 instance    | SQS read/write, S3, ECR pull, SSM Parameter Store read                   |
| `orders-dispatch-lambda-role` | Dispatch Lambda | SQS consume order-created, SQS publish order-dispatched, CloudWatch logs |
| `lambda_execution_role`       | EC2 stop Lambda | EC2 start/stop, CloudWatch logs                                          |

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

| Decision                       | Rationale                                                                                                                                                    |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| S3 backend (no DynamoDB lock)  | Remote state without overhead — single developer                                                                                                             |
| EC2 instance role              | No credentials in config or Parameter Store for app auth                                                                                                     |
| Separate IAM roles per Lambda  | Different trust boundaries and permission sets                                                                                                               |
| Direct Terraform resource refs | Avoids hardcoded ARNs, creates implicit dependency ordering                                                                                                  |
| Elastic IP                     | Stable public endpoint across EC2 stop/start cycles                                                                                                          |
| Scheduled EC2 stop             | Cost saving — hobby project, instance not needed 24/7                                                                                                        |
| SSH open to `0.0.0.0/0`        | GitHub Actions IPs are too broad to whitelist — private key is the security boundary. SSM Session Manager is the enterprise alternative (future improvement) |

---

## Related

- [orders](https://github.com/leighwest/orders) — Spring Boot application

## Versions

| Version                                                   | Description                                                                  |
| --------------------------------------------------------- | ---------------------------------------------------------------------------- |
| [v1.0.0](https://github.com/leighwest/orders/tree/v1.0.0) | Spring Boot 17, MySQL, GitHub Actions CI/CD via SSH, HTTPS via Let's Encrypt |
| [v2.0.0](https://github.com/leighwest/orders/tree/v2.0.0) | TBD                                                                          |
