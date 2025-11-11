#!/bin/bash
set -e

echo "Starting frontend deployment"

cd terraform
BUCKET_NAME=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
BACKEND_URL=$(terraform output -raw backend_url 2>/dev/null || echo "")
cd ..

if [ -n "$BACKEND_URL" ]; then
  BACKEND_API_URL="$BACKEND_URL" npm run build
else
  npm run build
fi

echo "Uploading to S3..."
aws s3 sync build/ s3://$BUCKET_NAME/ \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "index.html" \
  --exclude "*.json"

aws s3 cp build/index.html s3://$BUCKET_NAME/index.html \
  --cache-control "public, max-age=0, must-revalidate"

aws s3 sync build/ s3://$BUCKET_NAME/ \
  --exclude "*" \
  --include "*.json" \
  --cache-control "public, max-age=0, must-revalidate"

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*" \
  > /dev/null

echo "Deployment complete!"
