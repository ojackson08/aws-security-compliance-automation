# AWS Security & Compliance Auto-Remediation

An automated security pipeline that continuously monitors AWS resources, detects misconfigurations, and automatically remediates them without human intervention.

## 🏗️ Architecture

- **AWS Config:** Continuously monitors resource configurations and evaluates them against security rules (e.g., S3 Public Read Prohibited).
- **Amazon EventBridge:** Listens for AWS Config compliance change events (when a resource becomes NON_COMPLIANT).
- **AWS Lambda (Python/Boto3):** Automatically triggered by EventBridge to execute the remediation logic (e.g., blocking public access and enabling AES256 encryption on an S3 bucket).
- **Amazon SNS:** Sends real-time alerts to the security team detailing the violation and the automated actions taken.
- **Amazon GuardDuty:** Enabled to continuously monitor for malicious activity and unauthorized behavior.

## 🚀 The Problem It Solves

Security misconfigurations (like accidentally making an S3 bucket public) are the leading cause of cloud data breaches. Relying on manual audits is too slow. This project demonstrates a "SecOps" approach where security policies are enforced as code, and violations are remediated instantly—drastically reducing the window of vulnerability.

## 🛠️ Tech Stack

- **Cloud:** AWS
- **Infrastructure as Code:** Terraform
- **Security Services:** AWS Config, Amazon GuardDuty
- **Compute/Automation:** AWS Lambda, Amazon EventBridge
- **Notifications:** Amazon SNS
- **Language:** Python (Boto3)

## 💻 How to Deploy

1. Clone the repository.
2. Navigate to the `terraform/` directory.
3. Run `terraform init`.
4. Create a `terraform.tfvars` file and define your `security_email` variable.
5. Run `terraform apply` and type `yes`.
6. Confirm the SNS subscription sent to your email.
7. *Test it:* Manually create an S3 bucket and try to make it public. Watch AWS Config detect it and the Lambda function automatically lock it down within minutes.
