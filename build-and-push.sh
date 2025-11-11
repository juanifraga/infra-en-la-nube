#!/bin/bash
set -e

# Get the backend ALB URL from Terraform
cd terraform
BACKEND_URL=$(terraform output -raw backend_url 2>/dev/null || echo "http://localhost:3000")
cd ..

echo "Building Docker image with BACKEND_API_URL=$BACKEND_URL"

# Build the Docker image with the backend URL
docker build \
  --build-arg BACKEND_API_URL="$BACKEND_URL" \
  -t juanifraga/infra-en-la-nube:latest \
  .

echo "Pushing Docker image to registry..."
docker push juanifraga/infra-en-la-nube:latest

echo "Done! Docker image built and pushed with backend URL: $BACKEND_URL"
echo ""
echo "To update the running EC2 instance, SSH into it and run:"
echo "  docker pull juanifraga/infra-en-la-nube:latest"
echo "  docker stop \$(docker ps -q)"
echo "  docker run -d --restart unless-stopped -p 80:80 juanifraga/infra-en-la-nube:latest"
