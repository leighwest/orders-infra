# Changelog

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
