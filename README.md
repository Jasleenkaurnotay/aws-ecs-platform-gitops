# aws-ecs-platform-gitops

A production-grade, modular AWS ECS platform built with Terraform and deployed via GitHub Actions. This repo hosts a full 3-tier DevOps quiz application (React frontend, Flask backend, PostgreSQL/Aurora database) and serves as a reference implementation for teams looking to move beyond flat Terraform structures toward a clean, reusable, multi-environment IaC setup.

---

## What This Repo Does

This repo provisions and deploys a complete 3-tier application on AWS ECS Fargate using:

- **Modular Terraform** — reusable child modules for network, ECS, and database layers
- **Multi-environment support** — dev and prod environments from the same codebase, with separate state files and separate AWS IAM roles
- **GitHub Actions CI/CD** — one workflow for infrastructure, one for application build and deploy
- **OIDC authentication** — no static AWS credentials stored anywhere; GitHub Actions authenticates to AWS via federated identity

---

## What Makes This Different

Most tutorials and bootcamp projects use flat Terraform — everything in one directory, one environment, hardcoded values. This repo deliberately improves on that pattern:

| Pattern | Common approach | This repo |
|---|---|---|
| Terraform structure | Flat, single directory | Modular — root calls reusable child modules |
| Environments | One tfvars file | Separate tfvars + tfbackend per environment |
| State management | Single state file | Isolated state per environment in S3 |
| AWS auth in CI | Static `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` | OIDC — short-lived tokens, no long-lived credentials |
| Database | Same engine everywhere | Dev uses RDS PostgreSQL, Prod uses Aurora |
| NAT Gateways | Single NAT | Dev: single NAT (cost saving), Prod: one per AZ (HA) |
| DB password | Plain env var or hardcoded | AWS Secrets Manager + ECS secrets injection |
| Image tagging | `:latest` only | `:sha` tags via GitHub Actions for traceability |

---

## Architecture

```
Internet
    │
    ▼
Application Load Balancer (public subnets, 2 AZs)
    │
    ▼
ECS Fargate — Frontend (React/Node, port 80)
    │  via Service Connect (devops-quiz-namespace)
    ▼
ECS Fargate — Backend (Flask, port 8000)
    │
    ▼
Dev: RDS PostgreSQL  /  Prod: Aurora PostgreSQL (writer + reader)
    │
Secrets Manager — DB credentials injected at runtime
```

---

## Repo Structure

```
/
├── app/
│   ├── backend/        # Flask API, port 8000, gunicorn
│   └── frontend/       # React app, Node.js Express server, port 80
│
├── infra/
│   ├── modules/
│   │   ├── network/    # VPC, subnets, SGs, ALB, NAT gateways
│   │   ├── ecs/        # ECS cluster, task definitions, services
│   │   └── database/   # RDS (dev) or Aurora (prod)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── providers.tf
│   ├── oidc.tf         # GitHub OIDC provider + IAM roles
│   └── vars/
│       ├── dev.tfvars
│       ├── prod.tfvars
│       ├── dev.tfbackend
│       └── prod.tfbackend
│
└── .github/
    └── workflows/
        ├── infra.yml          # Terraform plan/apply/destroy
        └── build-deploy.yml   # Docker build, ECR push, ECS deploy
```

---

## GitHub Actions Workflows

### Infrastructure Workflow (`infra.yml`)

Manually triggered. Lets you select environment (dev/prod) and operation (plan/apply/destroy) from the GitHub Actions UI.

- Authenticates to AWS via OIDC — no stored credentials
- Uses environment-specific backend config and tfvars
- GitHub Actions environments (`dev`, `prod`) resolve the correct IAM role ARN via secrets

### Build & Deploy Workflow (`build-deploy.yml`)

Triggers automatically on push to `main` when files under `app/` change.

- Matrix build — frontend and backend built in parallel
- Images tagged with commit SHA for full traceability
- Runs DB migration as a one-off ECS task before deploying
- Updates ECS task definition with new image and forces service deployment

---

## Multi-Environment Pattern

The same Terraform code deploys to dev and prod. What differs per environment lives in `vars/`:

```
# dev.tfbackend
bucket = "mylabs-terraform-state"
key    = "dev/ecs-platform.tfstate"

# prod.tfbackend  
bucket = "mylabs-terraform-state"
key    = "prod/ecs-platform.tfstate"
```

Each environment has its own:
- S3 state file (isolated blast radius)
- AWS IAM role (separate permissions)
- GitHub Actions environment secret (`AWS_OIDC_ROLE_ARN`)
- tfvars (different instance sizes, NAT config, DB engine)

---

## Prerequisites

- AWS account with S3 bucket for Terraform state (`mylabs-terraform-state`)
- Terraform >= 1.5
- GitHub repo with Actions enabled
- Two GitHub Actions environments configured: `dev` and `prod`, each with `AWS_OIDC_ROLE_ARN` secret

---

## First-Time Setup

1. Run `terraform apply` locally once from `infra/` to bootstrap OIDC roles:
   ```bash
   terraform init -backend-config=vars/dev.tfbackend
   terraform apply -var-file=vars/dev.tfvars
   ```

2. Copy the IAM role ARNs from AWS console (IAM → Roles → `github-aws-dev-role` / `github-aws-prod-role`)

3. Add them to GitHub → Settings → Environments → `dev` / `prod` → Secrets → `AWS_OIDC_ROLE_ARN`

4. All future infra changes go through the GitHub Actions infra workflow

---

## The Application

A DevOps quiz platform for testing and tracking knowledge across DevOps topics.

- **Backend**: Flask, SQLAlchemy, PostgreSQL, port 8000. Config via environment variables and AWS Secrets Manager.
- **Frontend**: React (build output in `build/`), served by Node.js Express on port 80. Proxies `/api/*` to backend via ECS Service Connect.
- **Namespace**: `devops-quiz-namespace` (ECS Service Connect)
- **ECR repos**: `devopsquiz/frontend`, `devopsquiz/backend`

---

## Key Design Decisions

- `network_mode = awsvpc` and `launch_type = FARGATE` are hardcoded in the ECS module — not variablized, as these are fixed constraints for this platform
- ALB requires minimum 2 subnets in different AZs — enforced via tfvars structure
- `skip_final_snapshot = true` on RDS for dev — intentional for non-production teardown
- Terraform uses `:latest` image tag; GitHub Actions handles `:sha` tag updates separately
- One shared IAM task execution role for both frontend and backend services