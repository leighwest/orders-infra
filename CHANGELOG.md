# Changelog

---

## 2026-06-01

ACM certificate provisioned for `cupcakes-api.leighwest.dev` in `us-east-1` — replaces Let's Encrypt cert on the EC2. Auto-renews, no renewal hooks, no EC2 dependency.

CloudFront distribution added with two origins: EC2 (via `origin.cupcakes-api.leighwest.dev`) and S3 (closed page fallback). Origin group configured with automatic failover on 5xx — stop Lambda just stops the instance, CloudFront detects the failure and serves the closed page from S3 automatically. Path-based cache behaviours route API traffic directly to EC2; default behaviour uses the origin group for S3 fallback. Custom error responses serve `closed.html` on 403, 404, 502, and 504.

`orders-closed-page` S3 bucket added. Bucket policy restricts access to the CloudFront distribution via OAC.

`cupcakes-api.leighwest.dev` brought back into Terraform as a permanent CloudFront alias — no longer flipped by the start Lambda. `origin.cupcakes-api.leighwest.dev` created once via CLI with placeholder `1.1.1.1`; owned by start Lambda at runtime, not in Terraform state.

Start Lambda simplified — always updates `origin` DNS with the current EC2 IP regardless of instance state; health check via raw IP over HTTP to avoid SSL mismatch. State filter updated to exclude terminated instances.

Stop Lambda simplified — stops the instance only; no DNS flip. CloudFront failover handles the rest.

Instance type swapped from `t3.small` to `t4g.small` (Graviton/ARM). AMI updated to AL2023 ARM64 for `ap-southeast-4`. `lifecycle { ignore_changes = [associate_public_ip_address] }` added to prevent instance replacement when stopped.

Deploy artefacts S3 bucket added to EC2 instance IAM policy — required for SSM deploy script to pull files.

`static/closed.html` and `static/closed.webp` checked into repo as source of truth — upload manually via `aws s3 cp`.

---

## 2026-05-26

`cupcakes-api` A record removed from Terraform — owned by the start Lambda at runtime. `www.cupcakes-api` converted from A record to CNAME pointing at `cupcakes-api.leighwest.dev`.

## 2026-05-25

EC2 start Lambda added — starts the instance, waits for status OK, polls `/actuator/health`, then updates the `cupcakes-api` Route 53 A record with the new public IP.

Elastic IP removed. Instance now uses a dynamic public IP assigned on start. Start Lambda updates Route 53 automatically on each boot.

Scheduled start (6:50am AEST) and stop (8:00pm AEST) configured via EventBridge Scheduler, replacing the old EventBridge Rule. Native timezone support handles daylight savings time automatically.

Stop Lambda IAM tightened — scoped to `StopInstances` only. Separate least-privilege roles per Lambda and for the scheduler.

Dead code removed: `ec2_manager` IAM user and `eventbridge.tf`.

---

## 2026-05-23

Route 53 is now the authoritative DNS for `leighwest.dev`. All records migrated from Namecheap; nameservers updated. `cupcakes-api` TTL permanently set to 60s.

Lambda functions are now deployed from S3 rather than being packaged by Terraform. The pipeline builds and uploads zips keyed by git SHA before Terraform runs — clean separation of build and deploy.

---

## 2026-05-21 | v1.1.0

SSH access removed. EC2 is now accessed exclusively via SSM Session Manager — no open ports, IAM-controlled, full audit trail in CloudWatch.

Deploy files are staged through S3 rather than copied via SCP. The pipeline uploads files, EC2 pulls them via its instance role.

A scoped IAM user for GitHub Actions replaced the manually created user that had broad AdministratorAccess. Policy is explicit and version-controlled.

Instance ID is now looked up dynamically by tag rather than stored as a static secret.

---

## 2026-05-18 | v1.0.0

Initial release. Core AWS infrastructure provisioned via Terraform: EC2, SQS queues, ECR, S3, SES, IAM roles, EventBridge scheduled stop, and a Node.js dispatch Lambda wired to SQS.

EC2 instance role replaces credential-based auth — no AWS credentials in config or Parameter Store for the application.

GitHub Actions pipeline runs on every push to main: fmt check, validate, plan, apply. State stored remotely in S3.
