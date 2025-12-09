#!/bin/bash
MODULE_NAME="ECR"
info "🚀 Loaded module: $MODULE_NAME"

[[ -z "$PROFILE" ]] && PROFILE="default"
[[ -z "$REGION" ]] && REGION="ap-south-1"

show_menu() {
  echo "========================================="
  echo "     🐳 AWS ECR MANAGEMENT MENU"
  echo "========================================="
  echo "Profile: $PROFILE | Region: $REGION"
  echo "-----------------------------------------"
  echo "1) List Repositories"
  echo "2) Describe Repository"
  echo "3) Create Repository"
  echo "4) Delete Repository"
  echo "5) List Images"
  echo "6) Login to ECR (Docker)"
  echo "7) Build & Push Docker Image"
  echo "8) Return to Main Menu"
  echo "-----------------------------------------"
}

while true; do
  show_menu
  read -e -p "Select an option [1-8]: " choice
  case $choice in
    1)
      info "📋 Listing ECR Repositories..."
      aws ecr describe-repositories --query 'repositories[*].repositoryName' \
        --output table --profile "$PROFILE" --region "$REGION"
      ;;
    2)
      read -e -p "Enter repository name: " repo
      info "🔍 Describing repository '$repo'..."
      aws ecr describe-repositories --repository-names "$repo" \
        --profile "$PROFILE" --region "$REGION"
      ;;
    3)
      read -e -p "Enter new repository name: " repo
      info "🪄 Creating repository '$repo'..."
      aws ecr create-repository --repository-name "$repo" \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256 \
        --profile "$PROFILE" --region "$REGION"
      success "✅ Repository '$repo' created successfully."
      ;;
    4)
      read -e -p "Enter repository name to delete: " repo
      read -e -p "Are you sure you want to delete '$repo'? (y/N): " confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        info "🧹 Deleting repository '$repo'..."
        aws ecr delete-repository --repository-name "$repo" --force \
          --profile "$PROFILE" --region "$REGION"
        success "✅ Repository '$repo' deleted."
      else
        warn "❌ Operation cancelled."
      fi
      ;;
    5)
      read -e -p "Enter repository name: " repo
      info "📦 Listing images in '$repo'..."
      aws ecr list-images --repository-name "$repo" --query 'imageIds[*].imageTag' \
        --output table --profile "$PROFILE" --region "$REGION"
      ;;
    6)
      info "🔐 Logging in to ECR for Docker..."
      aws ecr get-login-password --region "$REGION" --profile "$PROFILE" | \
        docker login --username AWS --password-stdin \
        "$(aws sts get-caller-identity --profile "$PROFILE" --query 'Account' --output text).dkr.ecr.${REGION}.amazonaws.com"
      success "✅ Docker authenticated with ECR."
      ;;
    7)
      read -e -p "Enter ECR repository name: " repo
      read -e -p "Enter local Docker image name (default: myapp): " image
      image=${image:-myapp}
      read -e -p "Enter image tag (default: latest): " tag
      tag=${tag:-latest}

      account_id=$(aws sts get-caller-identity --profile "$PROFILE" --query 'Account' --output text)
      ecr_uri="${account_id}.dkr.ecr.${REGION}.amazonaws.com/${repo}:${tag}"

      info "🔧 Building Docker image: $image:$tag ..."
      docker build -t "$image:$tag" .

      info "🏷️ Tagging image for ECR: $ecr_uri ..."
      docker tag "$image:$tag" "$ecr_uri"

      info "⬆️ Pushing image to ECR..."
      docker push "$ecr_uri"

      success "✅ Image successfully pushed to $ecr_uri"
      ;;
    8)
      success "⬅️ Returning to main menu..."
      break
      ;;
    *)
      error "Invalid option."
      ;;
  esac
  echo ""
  read -e -p "Press ENTER to continue..." dummy
done
