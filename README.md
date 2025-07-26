# OpsGuru Hiring Assessment

## Problem

### Scenario

Your company is building an internal knowledge management platform for enterprise teams. The goal is to allow employees to collaborate on documentation, store company policies, and manage technical knowledge in a structured way.

To achieve this, your team has chosen [Wiki.js](https://js.wiki/), an open-source, self-hosted wiki platform that provides a powerful editor, authentication options, and content organization features.

### Objective

Your task is to design and deploy the infrastructure required to host Wiki.js on a cloud provider of your choice (AWS, GCP, or Azure) using Infrastructure as Code (Terraform, CDKs, Pulumi or cloud-specific IaC tools).

## Solution

### Requirements

Your deployment should ensure the following:

- Reliability: The solution should be highly available and able to handle multiple users.
- Security: The infrastructure should follow security best practices.
- Scalability: The deployment should accommodate growth over time.
- Observability: The system should have monitoring, logging, and alerting capabilities.
- Automation: The entire setup should be automated using IaC.

### Considerations

- Compute: Decide how you will run Wiki.js.
- Storage: Consider database and file storage requirements.
- Networking: Ensure the system is securely accessible.
- Scaling: Think about how to handle traffic spikes.
- Monitoring: Implement basic observability.

## Instructions

### Deliverables

1. Infrastructure as Code (IaC) implementation.
2. Architecture diagram showing the relevant components.
3. Deployment documentation, including instructions for setup and teardown.
4. Security considerations for handling sensitive data, authentication, and access control.

### Optional Resources

- [Wiki.js](https://js.wiki/)
- [Wiki.js Documentation](https://docs.requarks.io/)
- [Wiki.js GitHub Repository](https://github.com/Requarks/wiki)

## Documentation

Any candidate documentation for the solution should be placed in this section.

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
Deploying the solution is as easy as running "cdk deploy".
Similarly, destroying it can be done simply by using "cdk destroy".

You do need to set up the machine to be able to run the commands.
First thing to get is Python: https://www.python.org/downloads/  (or you can use the various package managers, depending on your OS.)
Next, you will need the CDK infrastructure installed as well.
Installation instructions can be found here: https://docs.aws.amazon.com/cdk/v2/guide/getting-started.html

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
