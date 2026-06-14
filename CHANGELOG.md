# Changelog

---

## 2026-06-14

Migrated DNS authority for `leighwest.dev` from Route 53 to Cloudflare. Route 53 hosted zone deleted; all 12 records recreated in Cloudflare DNS, managed via Terraform in the new `dns-infra` repo. All records confirmed resolving post-cutover via `dig @1.1.1.1`.

`ec2_start.py` Lambda DNS update ported from Route 53 `change_resource_record_sets` to Cloudflare API `PUT /zones/{zone_id}/dns_records/{record_id}`. Three new env vars added: `CF_API_TOKEN`, `CF_ZONE_ID`, `CF_RECORD_ID` — Terraform-managed, token stored as GitHub Actions secret. `ec2_stop.py` unchanged (no DNS calls).

`route53.tf` deleted from `orders-infra`. `acm.tf` updated to remove the Route 53 DNS validation record resource. `aws_route53_zone` and all `aws_route53_record` resources removed from Terraform state.

`issue-tracker-api.leighwest.dev` now publicly accessible via pre-existing Cloudflare Tunnel (`homelab-minipc`, UUID `ddb7ddd4-977c-434e-b74d-b71ab30f01f5`) running as a systemd service on the mini-PC. Swagger UI confirmed at `https://issue-tracker-api.leighwest.dev/swagger-ui/index.html`. Tunnel CNAME managed by `cloudflared`, excluded from Terraform.

---

## 2026-06-09

CloudFront origin group failover replaced with a CloudFront Function and KeyValueStore state flag. The origin group approach required CloudFront to wait for the EC2 origin to time out before failing over to the S3 closed page — a 50-60 second hang on first request after each stop. The CloudFront Function reads an `ec2_state` flag from KVS in-process before CloudFront attempts the origin at all; when the flag is `down`, the closed page is returned immediately with zero hang.

Stop Lambda updated to write `ec2_state=down` to KVS before stopping the instance. Start Lambda updated to write `ec2_state=up` after the health check passes. Both Lambdas bundle `botocore[crt]` for SigV4a signing of KVS API calls.

`/closed.webp` served via a dedicated CloudFront behaviour pointing directly to S3, bypassing the function — prevents an infinite loop where the closed page HTML triggers another function invocation when the browser fetches the image.

Path-based CloudFront behaviours and custom error responses removed — no longer needed now that the function handles routing. All HTTP methods supported on the default behaviour.

`orders-infra` tagged `v1.3.0` at commit `a9cff9e` (Postgres SSM parameter update) and `v1.4.0` at commit `38b44e8` (cupcake images bucket public access). Tags mark the Postgres migration and Java 21 work respectively — blog posts pending.

---

## 2026-06-05 | v1.4.0

Cupcake images S3 bucket made public — OAC removed, bucket policy updated to allow public reads. Required for enriched order email templates to render product images.

---

## 2026-06-04 | v1.3.0

SSM Parameter Store parameter renamed from `orders_mysql_password` to `orders_postgres_password`. EC2 instance IAM policy updated to reference new parameter ARN.

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
