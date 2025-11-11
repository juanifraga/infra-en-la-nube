#!/bin/bash
set -e

echo "Starting deployment!"

# Get the backend ALB URL from Terraform
cd terraform
BACKEND_URL=$(terraform output -raw backend_url 2>/dev/null || echo "http://localhost:3000")
EC2_IP=$(terraform output -raw public_ip 2>/dev/null)
cd ..

# Build the Docker image with the backend URL
docker build \
  --no-cache \
  --platform linux/amd64 \
  --build-arg BACKEND_API_URL="$BACKEND_URL" \
  -t juanifraga/infra-en-la-nube:latest \
  .

# Transfer image to EC2 via SSH
docker save juanifraga/infra-en-la-nube:latest | gzip | \
  ssh -i ~/.ssh/docusaurus-key.pem -o StrictHostKeyChecking=no ubuntu@$EC2_IP \
  'gunzip | sudo docker load'

# Restart the container
ssh -i ~/.ssh/docusaurus-key.pem -o StrictHostKeyChecking=no ubuntu@$EC2_IP \
  'sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true && \
   sudo docker run -d --restart unless-stopped -p 80:80 juanifraga/infra-en-la-nube:latest'

echo "Deployment complete!"