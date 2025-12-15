#!/bin/bash
# AWS Container Services Module — Manage EKS & ECS (Clusters, Tasks, Services, Express Mode & Cleanup)

while true; do
  clear
  echo "=========== AWS Container Services ==========="
  echo "1) EKS (Elastic Kubernetes Service)"
  echo "2) ECS (Elastic Container Service)"
  echo "3) Exit"
  read -e -p "Select option [1-3]: " mainopt

  case $mainopt in
    1)
      while true; do
        echo "=========== EKS Module ==========="
        echo "1) List Clusters"
        echo "2) Describe Cluster"
        echo "3) Update Kubeconfig"
        echo "4) Create Cluster"
        echo "5) Delete Cluster"
        echo "6) Back"
        read -e -p "Select option [1-6]: " eksopt

        case $eksopt in
          1) aws eks list-clusters ;;
          2)
            read -e -p "Enter Cluster Name: " cluster
            aws eks describe-cluster --name "$cluster"
            ;;
          3)
            read -e -p "Enter Cluster Name: " cluster
            aws eks update-kubeconfig --name "$cluster"
            ;;
          4)
            read -e -p "Enter Cluster Name: " cluster
            read -e -p "Enter Role ARN: " role_arn
            read -e -p "Enter Subnet IDs (comma-separated): " subnets
            read -e -p "Enter Security Group IDs (comma-separated): " sg
            echo "Creating EKS Cluster '$cluster'..."
            aws eks create-cluster \
              --name "$cluster" \
              --role-arn "$role_arn" \
              --resources-vpc-config subnetIds=${subnets},securityGroupIds=${sg}
            ;;
          5)
            read -e -p "Enter Cluster Name to Delete: " cluster
            echo "⚠️ Deleting EKS Cluster '$cluster'..."
            aws eks delete-cluster --name "$cluster"
            ;;
          6) break ;;
          *) echo "❌ Invalid option." ;;
        esac
      done
      ;;
    2)
      while true; do
        echo "=========== ECS Module ==========="
        echo "1) List Clusters"
        echo "2) Describe Cluster"
        echo "3) Create Cluster"
        echo "4) Run One-Time Container"
        echo "5) Deploy Persistent Service"
        echo "6) Delete ECS Resources"
        echo "7) Express Mode (Auto Setup + ECR)"
        echo "8) Back"
        read -e -p "Select option [1-8]: " ecsopt

        case $ecsopt in
          1)
            aws ecs list-clusters
            ;;
          2)
            read -e -p "Enter Cluster ARN or Name: " ecscluster
            aws ecs describe-clusters --clusters "$ecscluster"
            ;;
          3)
            read -e -p "Enter New ECS Cluster Name: " ecscluster
            aws ecs create-cluster --cluster-name "$ecscluster"
            ;;
          4)
            read -e -p "Enter ECS Cluster Name: " ecscluster
            read -e -p "Enter Container Name: " cname
            read -e -p "Enter Docker Image (e.g., nginx:latest): " cimage
            read -e -p "Enter CPU Units (e.g., 256): " ccpu
            read -e -p "Enter Memory (e.g., 512): " cmem
            read -e -p "Enter Subnet ID: " subnet
            read -e -p "Enter Security Group ID: " sg
            read -e -p "Use Fargate or EC2 launch type? [Fargate/EC2]: " launchtype

            task_def_file=$(mktemp)
            cat <<EOF > $task_def_file
{
  "family": "${cname}-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["${launchtype^^}"],
  "cpu": "$ccpu",
  "memory": "$cmem",
  "containerDefinitions": [
    {
      "name": "$cname",
      "image": "$cimage",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ]
    }
  ]
}
EOF

            echo "Registering ECS Task Definition..."
            aws ecs register-task-definition --cli-input-json file://$task_def_file

            echo "Running Container on ECS..."
            aws ecs run-task \
              --cluster "$ecscluster" \
              --launch-type "$launchtype" \
              --network-configuration "awsvpcConfiguration={subnets=[$subnet],securityGroups=[$sg],assignPublicIp=ENABLED}" \
              --task-definition "${cname}-task"

            rm -f $task_def_file
            ;;
          5)
            echo "=========== ECS Service Deployment ==========="
            read -e -p "Enter ECS Cluster Name: " ecscluster
            read -e -p "Enter Service Name: " sname
            read -e -p "Enter Docker Image (e.g., nginx:latest): " simage
            read -e -p "Enter CPU Units (e.g., 256): " scpu
            read -e -p "Enter Memory (e.g., 512): " smem
            read -e -p "Enter Desired Task Count (e.g., 2): " scount
            read -e -p "Enter Subnet IDs (comma-separated): " subnets
            read -e -p "Enter Security Group IDs (comma-separated): " sgroups
            read -e -p "Launch Type [Fargate/EC2]: " launchtype
            read -e -p "Attach Load Balancer? [y/n]: " lbchoice

            task_def_file=$(mktemp)
            cat <<EOF > $task_def_file
{
  "family": "${sname}-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["${launchtype^^}"],
  "cpu": "$scpu",
  "memory": "$smem",
  "containerDefinitions": [
    {
      "name": "$sname",
      "image": "$simage",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ]
    }
  ]
}
EOF

            echo "Registering ECS Task Definition..."
            aws ecs register-task-definition --cli-input-json file://$task_def_file

            if [[ "$lbchoice" == "y" || "$lbchoice" == "Y" ]]; then
              read -e -p "Enter Target Group ARN: " tgarn
              read -e -p "Enter Container Port (default 80): " port
              port=${port:-80}
              aws ecs create-service \
                --cluster "$ecscluster" \
                --service-name "$sname" \
                --task-definition "${sname}-task" \
                --desired-count "$scount" \
                --launch-type "$launchtype" \
                --network-configuration "awsvpcConfiguration={subnets=[$subnets],securityGroups=[$sgroups],assignPublicIp=ENABLED}" \
                --load-balancers "targetGroupArn=$tgarn,containerName=$sname,containerPort=$port"
            else
              aws ecs create-service \
                --cluster "$ecscluster" \
                --service-name "$sname" \
                --task-definition "${sname}-task" \
                --desired-count "$scount" \
                --launch-type "$launchtype" \
                --network-configuration "awsvpcConfiguration={subnets=[$subnets],securityGroups=[$sgroups],assignPublicIp=ENABLED}"
            fi

            echo "✅ ECS Service '$sname' created successfully."
            rm -f $task_def_file
            ;;
          6)
            echo "=========== ECS Cleanup ==========="
            echo "1) Delete Service"
            echo "2) Delete Task Definition"
            echo "3) Delete Cluster"
            echo "4) Back"
            read -e -p "Select option [1-4]: " delopt

            case $delopt in
              1)
                read -e -p "Enter Cluster Name: " ecscluster
                read -e -p "Enter Service Name: " sname
                echo "⚠️ Deleting ECS Service '$sname'..."
                aws ecs delete-service --cluster "$ecscluster" --service "$sname" --force
                ;;
              2)
                read -e -p "Enter Task Definition Family: " tfam
                echo "⚠️ Deregistering ECS Task Definition '$tfam'..."
                aws ecs deregister-task-definition --task-definition "$tfam"
                ;;
              3)
                read -e -p "Enter ECS Cluster Name: " ecscluster
                echo "⚠️ Deleting ECS Cluster '$ecscluster'..."
                aws ecs delete-cluster --cluster "$ecscluster"
                ;;
              4) ;;
              *) echo "❌ Invalid option." ;;
            esac
            ;;
          7)
            echo "=========== ECS Express Mode (Auto Setup + ECR) ==========="
            read -e -p "Enter App/Service Name: " sname
            read -e -p "Build and Push Local Image to ECR? [y/n]: " buildpush
            if [[ "$buildpush" == "y" || "$buildpush" == "Y" ]]; then
              REGION=$(aws configure get region)
              ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

              echo "🧱 Creating ECR Repository (if not exists)..."
              aws ecr create-repository --repository-name "$sname" >/dev/null 2>&1 || \
                echo "ℹ️ Repository already exists."

              ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$sname:latest"

              echo "🔐 Logging in to ECR..."
              aws ecr get-login-password --region "$REGION" | \
                docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

              echo "🐳 Building Docker image..."
              docker build -t "$sname" .

              echo "🚀 Tagging and pushing image to ECR..."
              docker tag "$sname:latest" "$ECR_URI"
              docker push "$ECR_URI"

              simage="$ECR_URI"
              echo "✅ Image pushed to ECR: $simage"
            else
              read -e -p "Enter Docker Image URI (ECR or DockerHub): " simage
            fi

            read -e -p "Enter Desired Task Count [default 1]: " scount
            scount=${scount:-1}
            read -e -p "Public Access? [y/n]: " public

            echo "🚀 Setting up ECS Express Mode for '$sname'..."

            aws ecs create-cluster --cluster-name "${sname}-cluster" >/dev/null 2>&1

            # Create default roles if missing
            aws iam get-role --role-name ecsTaskExecutionRole >/dev/null 2>&1 || \
              aws iam create-role --role-name ecsTaskExecutionRole \
              --assume-role-policy-document file://<(aws iam get-role --role-name AmazonECSTaskExecutionRolePolicy --query 'AssumeRolePolicyDocument' --output text 2>/dev/null) >/dev/null

            aws iam get-role --role-name ecsInfrastructureRoleForExpressServices >/dev/null 2>&1 || \
              aws iam create-role --role-name ecsInfrastructureRoleForExpressServices \
              --assume-role-policy-document file://<(aws iam get-role --role-name AmazonECSInfrastructureRoleForExpressServices --query 'AssumeRolePolicyDocument' --output text 2>/dev/null) >/dev/null

            task_def_file=$(mktemp)
            cat <<EOF > $task_def_file
{
  "family": "${sname}-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "$sname",
      "image": "$simage",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${sname}",
          "awslogs-region": "$(aws configure get region || echo us-east-1)",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

            aws ecs register-task-definition --cli-input-json file://$task_def_file >/dev/null

            subnet_id=$(aws ec2 describe-subnets --query "Subnets[0].SubnetId" --output text)
            sg_id=$(aws ec2 describe-security-groups --query "SecurityGroups[0].GroupId" --output text)

            aws ecs create-service \
              --cluster "${sname}-cluster" \
              --service-name "$sname" \
              --task-definition "${sname}-task" \
              --desired-count "$scount" \
              --launch-type "FARGATE" \
              --network-configuration "awsvpcConfiguration={subnets=[$subnet_id],securityGroups=[$sg_id],assignPublicIp=$( [[ $public == "y" ]] && echo ENABLED || echo DISABLED )}"

            echo "✅ Express Mode Service '$sname' deployed successfully!"
            rm -f $task_def_file
            ;;
          8)
            break
            ;;
          *)
            echo "❌ Invalid option."
            ;;
        esac
      done
      ;;
    3)
      echo "👋 Exiting..."
      exit 0
      ;;
    *)
      echo "❌ Invalid option."
      ;;
  esac
done
