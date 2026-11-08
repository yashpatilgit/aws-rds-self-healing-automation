
#!/bin/bash
set -e

# Project configuration
REGION="ap-south-1"

# Retrieve AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create unique S3 bucket name
BUCKET="aws-rds-self-healing-tfstate-${ACCOUNT_ID}"

# Create S3 bucket
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Enable bucket versioning
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

# Block public access
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Terraform state bucket $BUCKET is ready."
