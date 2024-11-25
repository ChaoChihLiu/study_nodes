#!/bin/bash

# Check if workspace is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <workspace>"
  exit 1
fi

WORKSPACE=$1

# Check if the workspace exists
if terraform workspace list | grep -q "^[* ] $WORKSPACE$"; then
  echo "Workspace '$WORKSPACE' already exists."
else
  echo "Workspace '$WORKSPACE' does not exist. Creating it..."
  terraform workspace new "$WORKSPACE"
fi

# Select the Terraform workspace
terraform workspace select "$WORKSPACE"

# Plan the configuration with the corresponding .tfvars file
echo "Running terraform plan..."
if terraform plan -var-file="${WORKSPACE}.tfvars"; then
  echo "Plan succeeded. Proceeding to apply..."
  terraform apply -var-file="${WORKSPACE}.tfvars"
else
  echo "Plan failed. Skipping apply."
  exit 1
fi
