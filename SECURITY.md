# Security Policy

## About This Project

`aws-security-compliance-automation` is a **security enforcement tool** developed by Merkaba AI Risk Management. It automatically remediates AWS security misconfigurations. As a tool with IAM permissions to modify AWS resources, its own security is of the highest importance — a compromised remediation function could be weaponized to create misconfigurations rather than fix them.

## Supported Versions

| Version | Supported |
|---|---|
| Current main | Yes |

## Reporting a Vulnerability

If you discover a security vulnerability in this project — including privilege escalation paths in the IAM Terraform, logic flaws that could cause legitimate resources to be incorrectly modified, or bypass techniques for the compliance rules — **please do not open a public GitHub issue.**

Report vulnerabilities directly to:

**Email:** security@merkabacreatives.org
**Subject line:** `[SECURITY] aws-security-compliance-automation — <brief description>`

We will acknowledge receipt within **48 hours** and provide a remediation timeline within **5 business days**.

## Security Design Notes

- The Lambda execution role is scoped to the minimum permissions required for each remediation action.
- All remediation actions are logged to CloudTrail before execution.
- SNS alerts are sent for every remediation action, ensuring human visibility.
- The Terraform state should be stored in an encrypted S3 backend with DynamoDB state locking.
- GuardDuty is enabled as a complementary threat detection layer.

## Responsible Disclosure

We follow coordinated disclosure. We ask that you give us reasonable time to investigate and patch before public disclosure.

## Contact

Merkaba AI Risk Management
security@merkabacreatives.org
https://merkabacreatives.org/ai-risk
