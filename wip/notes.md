aws --profile=security-admin sts get-caller-identity

kubectl apply -f https://s3.us-west-2.amazonaws.com/amazon-eks/docs/eks-console-full-access.yaml

eksctl create iamidentitymapping --cluster prod-green-k8s --region=eu-west-2 --arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/Test-Developers --group eks-console-dashboard-full-access-group --no-duplicate-arns

eksctl create iamidentitymapping --cluster prod-green-k8s --region=eu-west-2 --arn arn:aws:iam::${AWS_ACCOUNT_ID}:user/Test-Developers --group eks-console-dashboard-restricted-access-group --no-duplicate-arns
