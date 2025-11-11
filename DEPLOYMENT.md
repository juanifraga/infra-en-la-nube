# Deployment Guide

#### 1. Deploy Backend Infrastructure

```bash
cd terraform
terraform apply
```

This will create:

- Application Load Balancer
- 2 (or more) Backend EC2 instances
- RDS PostgreSQL database
- All necessary security groups

#### 2. Build and Push Frontend Docker Image

After the backend is deployed, build the frontend with the correct backend URL:

```bash
./build-and-push.sh
```

This script will:

1. Get the backend ALB URL from Terraform outputs
2. Build the Docker image with `BACKEND_API_URL` set
3. Push the image to Docker Hub

#### 3. Update the Frontend EC2 Instance

SSH into the frontend EC2 instance and pull the new image:

```bash
# Get the frontend IP
cd terraform
terraform output web_url

# SSH into the instance
ssh -i ~/.ssh/docusaurus-key.pem ubuntu@<FRONTEND_IP>

# Pull and restart the container
docker pull juanifraga/infra-en-la-nube:latest
docker stop $(docker ps -q)
docker run -d --restart unless-stopped -p 80:80 juanifraga/infra-en-la-nube:latest
```
