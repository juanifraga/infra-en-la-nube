# Deployment Guide

## Prerequisites

- AWS credentials configured (`~/.aws/credentials`)
- SSH key at `~/.ssh/docusaurus-key.pem`
- Docker installed and running
- Terraform installed

## Deployment Steps

### 1. Deploy Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform apply
```

This will create:

- **Frontend**: EC2 instance running Docusaurus in Docker
- **Backend**: Application Load Balancer with 2+ EC2 instances
- **Database**: RDS PostgreSQL database
- **Networking**: Security groups, VPC configuration
- **Storage**: S3 bucket for Lambda

### 2. Deploy Frontend (Automated)

After infrastructure is deployed, run:

```bash
./build-and-push.sh
```

This script **automatically**:

1. Detects backend ALB URL from Terraform outputs
2. Builds Docker image with `--no-cache` (always fresh)
3. Builds for `linux/amd64` platform (EC2 compatible)
4. Transfers image directly to EC2 via SSH (no Docker Hub needed)
5. Stops old container and starts new one
6. Displays deployment URLs

## Accessing Your Application

After deployment completes:

- **Frontend**: `http://<frontend-ec2-ip>` (shown in script output)
- **Backend API**: `http://<alb-dns-name>` (shown in script output)
- **Comments Page**: `http://<frontend-ec2-ip>/comments`

## Architecture

```
┌─────────────────┐
│   CloudFront    │  (Optional future improvement)
└────────┬────────┘
         │
┌────────▼────────┐
│  Frontend EC2   │  ← Docusaurus/React (Docker)
│  Port 80        │
└────────┬────────┘
         │
         │ API calls
         │
┌────────▼────────┐
│   Backend ALB   │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼──┐  ┌──▼───┐
│ BE-1 │  │ BE-2 │  ← Express.js APIs
└───┬──┘  └──┬───┘
    │        │
    └────┬───┘
         │
    ┌────▼────┐
    │   RDS   │  ← PostgreSQL
    └─────────┘
```

## Tips

- **Faster deployments**: The script uses direct SSH transfer instead of Docker Hub push/pull
- **Always fresh**: `--no-cache` ensures your latest code changes are included
- **Automatic detection**: Backend URL is automatically retrieved from Terraform
- **One command**: Just run `./build-and-push.sh` after any frontend changes
