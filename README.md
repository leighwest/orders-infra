# orders-infra

Terraform infrastructure for the [orders](https://github.com/leighwest/orders) Spring Boot service, deployed on AWS in `ap-southeast-4` (Melbourne).

---

## What This Provisions

| Resource                  | Description                                                                 |
| ------------------------- | --------------------------------------------------------------------------- |
| EC2 instance              | `t3.small` — runs the orders Spring Boot app in Docker                      |
| Elastic IP                | Static public IP for the EC2 instance                                       |
| Security group            | Inbound HTTP, HTTPS, SSH rules                                              |
| IAM instance role         | EC2 identity — grants SQS, S3, and ECR access without credentials in config |
| ECR repository            | Docker image registry for the orders service                                |
| SQS: `order-created`      | Orders service publishes here; dispatch Lambda consumes                     |
| SQS: `order-dispatched`   | Dispatch Lambda publishes here; orders service consumes                     |
| Lambda: `orders-dispatch` | Node.js — bridges the two SQS queues, simulates a dispatch microservice     |
| Lambda: `ec2_stop_auto`   | Python — stops the EC2 instance on a nightly schedule (cost control)        |
| EventBridge rule          | Triggers `ec2_stop_auto` at 11:50 PM AEDT / 10:50 PM AEST                   |
| S3 bucket                 | Stores cupcake images, accessed by the orders service                       |
| SES IAM user              | SMTP credentials for sending order emails                                   |
| SSM Parameters            | Stores SMTP credentials securely                                            |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- AWS CLI configured with credentials for `ap-southeast-4`
- An existing SSH key pair (or generate one — see below)

---

## Local Setup

1. Clone the repo:

```bash
git clone https://github.com/leighwest/orders-infra.git
cd orders-infra
```

2. Copy the example vars file and populate it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Required values in `terraform.tfvars`:

```hcl
AWS_ACCESS_KEY      = "AKIA..."
AWS_SECRET_KEY      = "..."
PERSONAL_IP_ADDRESS = "your.ip.address/32"
INSTANCE_ID         = "i-..."        # only needed after first apply
ECR_REPO_NAME       = "orders"
```

3. Generate an SSH key pair if needed:

```bash
ssh-keygen -t rsa -b 4096 -f orders
# produces: orders (private key) and orders.pub (public key)
# both are gitignored
```

4. Initialise and apply:

```bash
terraform init
terraform plan
terraform apply
```

---

## Credentials

AWS credentials are **never stored in this repo**.

- **Locally:** populate `terraform.tfvars` (gitignored)
- **CI/CD:** stored as GitHub Actions secrets

The EC2 instance authenticates to AWS (SQS, S3, ECR) via an IAM instance role — no credentials are needed in the Spring Boot application config.

---

## Event-Driven Flow

```
Orders Service (EC2)
  └── publishes → [SQS: order-created]
                        ↓
              Dispatch Lambda (orders-dispatch)
                        ↓
              publishes → [SQS: order-dispatched]
                                    ↓
                       Orders Service (EC2)
```

The `aws_lambda_event_source_mapping` in `lambda.tf` wires `order-created` directly to the dispatch Lambda. AWS manages the polling — no configuration required beyond the mapping itself.

---

## Cost Notes

- EC2 `t3.small` — the nightly EventBridge rule stops the instance automatically to minimise cost
- ECR — ~$0.10/GB/month storage; negligible for a single image
- SQS — free tier covers well beyond this workload
- Lambda — well within free tier for this usage pattern

---

## Related

- [orders](https://github.com/leighwest/orders) — the Spring Boot application this infrastructure runs
