# AWS Security Compliance Automation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AWS](https://img.shields.io/badge/AWS-Config%20%7C%20Lambda%20%7C%20EventBridge-orange.svg)](https://aws.amazon.com/)
[![Security](https://img.shields.io/badge/security-auto--remediation-red.svg)](https://github.com/ojackson08/aws-security-compliance-automation)
[![Maintained by Merkaba AI Risk](https://img.shields.io/badge/maintained%20by-Merkaba%20AI%20Risk-blueviolet)](https://merkabacreatives.org/ai-risk)

**Production security auto-remediation for AI workloads — a core component of Merkaba AI Risk Management's Infrastructure Compliance service.**

---

## Overview

AWS Security Compliance Automation is an event-driven remediation engine that detects and corrects security misconfigurations in AWS environments in seconds — not weeks. AWS Config continuously monitors resource configurations; when a violation is detected, EventBridge triggers a Lambda function that auto-remediates the issue and sends a high-signal alert via SNS.

This tool is a core component of Merkaba AI Risk Management's **AI Infrastructure Compliance** engagements, used to harden the AWS environments that host AI workloads, agent pipelines, and LLM APIs.

---

## Architecture

```
AWS Config (continuous monitoring)
    │
    ▼
EventBridge (violation detected)
    │
    ▼
Lambda (auto-remediation)
    ├── Block public S3 bucket access
    ├── Revoke open security group rules
    ├── Flag overly permissive IAM roles
    └── SNS alert → team notification
```

---

## What It Remediates

| Misconfiguration | Severity | Remediation |
|---|---|---|
| Public S3 bucket | CRITICAL | Auto-blocks public access via S3 Block Public Access API |
| Open security groups (0.0.0.0/0) | HIGH | Revokes overly permissive inbound rules |
| Overly permissive IAM roles | HIGH | Flags for human review + sends alert |
| Unencrypted EBS volumes | MEDIUM | Alerts and tags for remediation |
| CloudTrail disabled | HIGH | Re-enables and alerts |

---

## Infrastructure

Provisioned entirely via Terraform:

- **AWS Config** — Continuous resource configuration monitoring
- **Amazon EventBridge** — Rule-based event routing
- **AWS Lambda** — Serverless remediation engine
- **Amazon SNS** — High-signal alert delivery
- **Amazon GuardDuty** — Continuous threat detection
- **IAM** — Least-privilege remediation roles

---

## Deployment

```bash
cd terraform/
terraform init
# Create terraform.tfvars with your security_email variable
terraform apply
```

Set the `SNS_ALERT_TOPIC_ARN` environment variable on the Lambda function to configure alert delivery.

---

## Case Study / Usage Notes

**Deployment at Merkaba AI Risk Management:**

During an AI Infrastructure Compliance engagement for a healthcare AI startup, this tool was deployed into an AWS environment hosting a multi-agent clinical decision support system. Within the first 24 hours of deployment, it detected and auto-remediated 4 public S3 buckets (two of which contained model training data), 7 open security group rules, and 2 IAM roles with `AdministratorAccess` attached to Lambda functions. The client's window of vulnerability was reduced from a previous average of 11 days (time from misconfiguration to human detection) to under 30 seconds.

---

## Integration with Merkaba Security Stack

- [`ai-codebase-audit-engine`](https://github.com/ojackson08/ai-codebase-audit-engine) — Codebase audit precedes infrastructure hardening
- [`merka-prompt-shield`](https://github.com/ojackson08/merka-prompt-shield) — Application-layer defense complement
- [`hermes-agent-memory-vault`](https://github.com/ojackson08/hermes-agent-memory-vault) — Secure memory backend for agent workloads
- [`agenthandoff`](https://github.com/ojackson08/agenthandoff) — Secure agent state transfer in the same hardened environment

---

## License

MIT License — see [LICENSE](./LICENSE) for details.

---

## Contact

**Merkaba AI Risk Management**
security@merkabacreatives.org
https://merkabacreatives.org/ai-risk
*Atlanta, GA — Remote Worldwide*
