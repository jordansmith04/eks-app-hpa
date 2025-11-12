# EKS Production Microservice Deployment

This repository demonstrates a production-grade microservice deployment on Amazon EKS, featuring the following key components:

- Helm Chart (helm/): Deploys an Nginx microservice with defined CPU requests/limits and a Horizontal Pod Autoscaler (HPA) configured for CPU utilization.

- AWS LoadBalancer Controller Integration: Uses a Kubernetes Ingress resource with specific AWS annotations to provision an Application Load Balancer (ALB).

- Terraform (terraform/): Provisions the necessary IAM Role and Policy required by the AWS LoadBalancer Controller to interact with the AWS API and create ALBs.

## Prerequisites

- An existing EKS Cluster with an OIDC provider enabled.

- The AWS LoadBalancer Controller must be installed on the EKS cluster after the Terraform IAM Role is provisioned.

- Helm and Terraform CLIs installed.

- AWS CLI configured with appropriate permissions.

### 1. Deploy AWS IAM Role using Terraform

The AWS LoadBalancer Controller runs as a service account and needs permissions to call EC2 and ELB APIs. This step creates the required IAM Role for Service Accounts (IRSA).

1. Navigate to the terraform directory and update variables.tf with your cluster's OIDC Issuer URL.

2. Initialize and apply the configuration:
```
cd terraform
terraform init
terraform apply
```

3. Crucially, save the output ARN:
```
ALB_ROLE_ARN=$(terraform output -raw alb_controller_role_arn)
echo $ALB_ROLE_ARN
```

### 2. Install the AWS LoadBalancer Controller using Helm

Using the IAM Role ARN created in the previous step, install the controller into your cluster.

1. Add the EKS chart repository:
```
helm repo add aws-load-balancer-controller [https://aws.github.io/eks-charts](https://aws.github.io/eks-charts)
helm repo update
```

2. Install the controller into the kube-system namespace. <u>Make sure to replace $ALB_ROLE_ARN with the value saved in Step 1.</u>
```
helm upgrade -i aws-load-balancer-controller \
  aws-load-balancer-controller/aws-load-balancer-controller \
  --set clusterName=<YOUR_CLUSTER_NAME> \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ALB_ROLE_ARN" \
  -n kube-system
```
Note: Replace <YOUR_CLUSTER_NAME> with the name of the cluster (not created in this repo)

3. Verify the deployment:
```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### 3. Deploy the Microservice using Helm

Once the LoadBalancer Controller is running, you can deploy the application. The Ingress resource will now be picked up by the new controller.

1. Navigate back to the root of the project.

2. Deploy the chart:
```
helm install prod-app ./helm
```

3. Check the status of the Ingress, and within a few minutes, you should see an AWS ALB provisioned:
```
kubectl get ingress
```