# Deployment Guide

## Prerequisites

- AWS credentials configured (`~/.aws/credentials`)
- Terraform installed

## Deploy

### 1. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

### 2. Deploy Frontend

```bash
./deploy-to-s3.sh
```

## Access

- **Frontend**: `https://<cloudfront-domain>` (shown after deployment)
- **Backend API**: `http://<alb-dns-name>/comments`
