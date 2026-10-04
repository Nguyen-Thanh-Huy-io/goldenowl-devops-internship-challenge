# Golden Owl DevOps Internship - Solution

A Node.js (Express) app, containerized and deployed on **Amazon ECS (Fargate)** behind an **Application Load Balancer** with **HTTPS** and **target-tracking auto scaling**. All cloud infrastructure is provisioned with **Terraform** and deployed through **GitHub Actions**.

```bash
curl https://goldenowl.thanhhuy0210.id.vn
# {"message":"Welcome warriors to Golden Owl!"}
```

## 📌 Submission Overview

| Requirement | Implementation Details | Status |
|---|---|---|
| Live Application URL | [https://goldenowl.thanhhuy0210.id.vn](https://goldenowl.thanhhuy0210.id.vn) | ✅ Done |
| Source Code | [GitHub repository](https://github.com/Nguyen-Thanh-Huy-io/goldenowl-devops-internship-challenge) | ✅ Done |
| Container Registry | Amazon ECR `goldenowl-internship-staging` (immutable tags = commit SHA, scan on push) | ✅ Done |
| Final Docker Image Size | **<ECR_SIZE> MB** compressed in ECR / <DISK_SIZE> MB on disk (multi-stage, Node.js 20 Alpine, non-root) | ✅ Done |
| Visual Flow Diagram | [`diagram/cicd-flow.png`](diagram/cicd-flow.png), [`diagram/aws-architecture.png`](diagram/aws-architecture.png) (manually created in draw.io) | ✅ Done |
| CI Automation | GitHub Actions [`ci.yml`](.github/workflows/ci.yml): test, build, Trivy scan on push to `feature/**` | ✅ Done |
| CD Automation | GitHub Actions [`cd.yml`](.github/workflows/cd.yml): build, push to ECR, deploy to ECS on merge to `master` (AWS access via OIDC) | ✅ Done |
| Infrastructure as Code | Terraform ([`terraform/`](terraform/)): VPC, ALB, ECR, ECS Fargate, IAM, ACM, Route 53 | ✅ Done |
| Load Balancing & Auto Scaling | AWS ALB + ECS Fargate service (Target Tracking CPU 60%, min 2 / max 4 tasks) | ✅ Done |
| Security Scanning (Bonus ⭐) | Trivy in CI (SARIF report, gate on CRITICAL) + ECR scan on push | ✅ Done |
| HTTPS Support (Bonus ⭐) | ACM certificate on the ALB, HTTP redirects to HTTPS | ✅ Done |
| Automatic Rollback (Bonus ⭐) | ECS deployment circuit breaker with rollback + `wait-for-service-stability` in CD | ✅ Configured |
| Terraform (Bonus ⭐) | All AWS resources defined in Terraform | ✅ Done |

### Image size evidence
![ECR image size](diagram/ecr-image-size.png)
![docker images](diagram/docker-images.png)

## ✨ Highlights

- **Image optimization:** cut the image from 315 MB to 198 MB on disk (64 MB to 49.1 MB compressed) by finding dev-only packages wrongly listed in `dependencies`.
- **Security:** Trivy scan in CI with a gate on CRITICAL findings; Express dependencies patched with `npm audit fix` (0 production vulnerabilities); ECR scan on push.
- **No stored AWS credentials:** GitHub Actions authenticates through OIDC, restricted to this repo's `master` branch.
- **Traceable releases:** immutable ECR tags using the commit SHA, plus a deployment circuit breaker for automatic rollback.
- **Iterative history:** small, focused commits across feature branches and pull requests.

## 🎨 Diagrams (drawn manually in draw.io)

### CI/CD flow
![CI/CD flow](diagram/cicd-flow.png)

### AWS architecture
![AWS architecture](diagram/aws-architecture.png)

Source file: `diagram/architecture.drawio`

## 🐳 Docker image

`src/Dockerfile` (multi-stage, non-root):

- Stage 1 installs production dependencies only (`npm ci --omit=dev`).
- Stage 2 copies only `node_modules` and the app source and runs as the `node` user.
- `.dockerignore` keeps `node_modules`, `.git`, `.env` and docs out of the build context.
- npm, corepack and yarn are removed from the final image. This does not shrink the image (deleted files remain in earlier layers) but reduces attack surface and removes npm's bundled packages from vulnerability scans.

| Step | On disk | Compressed |
|---|---|---|
| First multi-stage build | 315 MB | 64 MB |
| Moved `eslint-plugin-jest` and `nodemon` to `devDependencies` | 198 MB | 49.1 MB |

The two dev-only packages were pulling about 100 MB of `typescript`, `@typescript-eslint` and `eslint` into the production image.

Base image is `node:20-alpine`. Node 20 has passed its end-of-life date, so upgrading is recommended for real use: change the two `FROM` lines and `node-version` in the workflows. Node 22 produced a larger image in my test (242 MB on disk / 61.4 MB compressed).

## 🔁 CI/CD

| Workflow | Trigger | Steps |
|---|---|---|
| `ci.yml` | push to `feature/**`, PR into `master` | `npm ci`, `npm test`, build image, Trivy scan (SARIF report, fails on CRITICAL) |
| `cd.yml` | push to `master` | test, build image, push to ECR (tag = commit SHA), render task definition, deploy to ECS and wait for stability |

- AWS authentication uses **GitHub OIDC**: no long-lived access keys. The IAM role trusts only this repository's `master` branch.
- ECR tags are **immutable** and use the commit SHA, so every deployment is traceable.
- CI builds the image only to validate and scan it. CD rebuilds and pushes the image that is actually deployed.

## 🏗️ Infrastructure (Terraform, `terraform/`)

| File | Resources |
|---|---|
| `vpc.tf` | VPC, internet gateway, 2 public subnets (2 AZs), route table |
| `security_groups.tf` | ALB (80/443 from internet), ECS tasks (3000 only from ALB) |
| `ecr.tf` | ECR repository (immutable tags, scan on push), lifecycle policy (keep 10 images) |
| `alb.tf` | ALB, target group (ip, port 3000, `GET /`), listener 80 (redirect), listener 443 |
| `dns_https.tf` | ACM certificate (DNS validation), Route 53 validation and alias records |
| `ecs.tf` | ECS cluster, Fargate task definition, service with deployment circuit breaker |
| `autoscaling.tf` | Application Auto Scaling target and CPU target-tracking policy |
| `iam.tf` | Task execution role, GitHub OIDC provider and deploy role |
| `cloudwatch.tf` | Log group for container logs |

**Auto scaling:** target tracking on `ECSServiceAverageCPUUtilization` at 60%, min 2 / max 4 tasks. ECS publishes the metric to CloudWatch and Application Auto Scaling manages the scale-out and scale-in alarms.

## 🧭 Design decisions

- **Public subnets, no NAT Gateway.** Tasks have public IPs but their security group only accepts traffic from the ALB. This avoids the NAT Gateway cost. A production setup would use private subnets with NAT or VPC endpoints.
- **ECS Fargate** instead of EC2 + Auto Scaling Group: no servers to manage, native rolling deployments and circuit breaker.
- **Flat Terraform layout** because there is a single environment; would be refactored into modules for multiple environments.
- **Local Terraform state** (git-ignored) for speed; a team setup would use an S3 backend with locking.
- Terraform ignores `task_definition` and `desired_count` changes on the ECS service, because CD registers new task definitions and auto scaling manages the task count.

## ⚠️ Manual steps outside Terraform

- The domain `thanhhuy0210.id.vn` was registered at PA Vietnam and its name servers were pointed to Route 53.
- The Route 53 hosted zone was created once with the AWS CLI. Terraform reads it with a data source and manages the records inside it.
- The `AWS_ROLE_ARN` GitHub secret was set by hand from the Terraform output.

## 💻 Run locally

With Docker:

```bash
docker build -t goldenowl-app ./src
docker run --rm -p 3000:3000 goldenowl-app
```

## 🧹 Deploy / destroy

```bash
cd terraform
terraform init
terraform apply
terraform destroy   # then delete the Route 53 hosted zone manually
```

# Golden Owl DevOps Internship - Technical Test
At Golden Owl, we believe in treating infrastructure as code and automating resource provisioning to the fullest extent possible. 

In this technical test, we challenge you to create a robust CI build pipeline using GitHub Actions. You have the freedom to complete this test in your local environment.

## Your Mission 🌟
Your mission, should you choose to accept it, is to build a CI/CD pipeline and deploy the application by:
1. Forking this repository to your personal GitHub account.
2. Dockerizing a Node.js application, keeping the image **as lightweight as possible** (Please state the final image size in your repository's README so we can see the result of your optimization).
3. Establishing an automated CI/CD build process using GitHub Actions workflow and a container registry service such as DockerHub or Amazon Elastic Container Registry (ECR) or similar services.
4. Initiating CI tests automatically when changes are pushed to the feature branch on GitHub.
5. Utilizing GitHub Actions for Continuous Deployment (CD) to deploy the application to major cloud providers like AWS EC2, AWS ECS or Google Cloud (please submit the deployment link).
6. Deploying the application behind a **load balancer** with **auto scaling** enabled.
7. Provisioning **all cloud infrastructure using Infrastructure as Code (IaC)** such as Terraform, AWS CloudFormation, AWS CDK, or Pulumi. Resources created manually through the cloud console will not be accepted. 
8. Providing a **visual flow diagram** of your workflow and architecture, **created by you without the use of AI** (see [Visual Flow Diagram](#visual-flow-diagram-required-) below).

## Visual Flow Diagram (Required) 🎨
A `visual flow diagram` is **mandatory** for this test. It must illustrate the sequence of tasks you performed and the architecture you deployed, including:
- The CI/CD flow
- The deployed application's infrastructure

**The diagram must be created manually by you and must not be generated by AI.** This means no AI image generators and no AI tools that produce a diagram from a text prompt or from your code. 

Reference tools for creating visual flow diagrams:
- https://www.drawio.com/
- https://excalidraw.com/
- https://www.eraser.io/

## The Bigger Picture 🌏
This test is designed to evaluate your ability to implement modern automated infrastructure practices while demonstrating a basic understanding of Docker. In your solution, we encourage you to prioritize readability, maintainability, and the principles of DevOps.

## How We Evaluate 🎯
| Area | Weight |
|---|---|
| CI/CD pipeline (tests on push, build, push to registry, deploy) | 25% |
| Deployment works behind a load balancer with a real auto scaling policy | 25% |
| Visual flow diagram (accurate, manually created) | 20% |
| Infrastructure as code / repo quality / commit history | 20% |
| Docker image optimization (size, multi-stage, non-root, .dockerignore) | 10% |

## Bonus (Optional) ⭐
- Image vulnerability scan in CI (e.g. Trivy)
- HTTPS on the load balancer
- Automatic rollback on failed deployment
- Infrastructure defined with Terraform

## Submission Guidelines 📬
Your solution should be showcased in a public GitHub repository. We encourage you to commit early and often. We prefer to see a history of iterative progress rather than a single massive push. 

Your submission must include:
- The URL of your public GitHub repository
- The deployment link of your running application
- The visual flow diagram (manually created, not AI-generated)
- The final Docker image size

When you've completed the assignment, kindly share these with us.

## Running the Node.js Application Locally 🏃‍♂️
This is a Node.js application, and running it locally is straightforward:
- Navigate to the `src` directory by executing `cd src`.
- Install the project's dependencies listed in the package.json file by running `npm i`.
- Execute `npm test` to run the application's tests.
- Start the HTTP server with `npm start`.

You can test it using the following command:
```shell
curl localhost:3000
```
You should receive the following response:
```json
{"message":"Welcome warriors to Golden Owl!"}
```

Are you ready to embark on this DevOps journey with us? 🚀 Best of luck with your assignment! 🌟