# Wiki.js Infrastructure Architecture - ECS Fargate Sandbox

This repository contains the infrastructure-as-code configuration for a high-availability deployment of Wiki.js on AWS using ECS Fargate. The project maps out the localized network decoupling, a managed PostgreSQL backend tier, and secure application routing profiles.

---

### Architecture Diagram

                 /---------------\
                 |     User      |
                 \---------------/
                         |
                         |
                        \/
                 /---------------\
                 |    AWS WAF    |
                 \---------------/
                         |
                         |
        /-----------------------------------\
        |       VPC      |                  |
        |               \/                  |
        |         /--------------\          |
        |         |  ALB (ELB)   |          |
        |         \--------------/          |
        |                |                  |
        |    /-----------+-------------\    |
        |    |  Private  |   Subnet    |    |
        |    |          \/             |    |
        |    |  /-------------------\  |    |
        |    |  |  Fargate Service  |  |    |
        |    |  |  Running Wiki.Js  |  |    |
        |    |  |       Image       |  |    |
        |    |  \-------------------/  |    |
        |    |           |             |    |
        |    |           |             |    |
        |    |          \/             |    |
        |    |  /-------------------\  |    |
        |    |  |  RDS PostgreSQL   |  |    |
        |    |  |     Instance      |  |    |
        |    |  \-------------------/  |    |
        |    |                         |    |
        |    \-------------------------/    |
        |                                   |
        \-----------------------------------/

### Deployment Instructions:
Deploying the solution is as easy as running "terraform apply".
Similarly, destroying it can be done simply by using "terraform destroy".

You do need to set up the machine to be able to run the commands.
First thing to get is the Terraform binary (v1.5+ recommended): `choco install terraform`, `brew install hashicorp/tap/terraform` or whatever your package manager is.
Next, you will need to install the official AWS Command Line Interface to manage secure terminal sessions.
Detailed instructions here: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### Security Considerations:
Security best practices followed:
- Database and backend containers launched in private subnets.
- Database password auto-generated and stored in Secrets Manager.
- Access to database restricted to the ECS containers, using security groups.
- Internet access allowed only through ALB.
- Internet access restricted to Israel, using AWS WAF.

Further hardening possible:
- Database and containers can be launched in **isolated** subnets
- ALB access can be restricted to HTTPS, if a domain name is available, with calls to HTTP redirected to HTTPS
- WAF rules can be further refined, to restrict internet access as tightly as feasible
