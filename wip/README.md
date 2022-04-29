https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_permissions-to-switch.html#roles-usingrole-createpolicy
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_passwords_account-policy.html
https://docs.aws.amazon.com/vpc/latest/userguide/vpc-policy-examples.html
https://aws.amazon.com/premiumsupport/knowledge-center/eks-iam-permissions-namespaces/
https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
https://aws.amazon.com/blogs/containers/de-mystifying-cluster-networking-for-amazon-eks-worker-nodes/
https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

brew install kubernetes-cli
brew install kubectx
brew install aws-iam-authenticator


from the AWS console, create a new user Admin which has a valid access key and two policies attached:

  arn:aws:iam::aws:policy/IAMFullAccess
  arn:aws:iam::aws:policy/AmazonS3FullAccess
  arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess


aws configure --profile admin


cat ~/.aws/credentials

[admin]
aws_access_key_id = ...
aws_secret_access_key = ...


aws --profile admin iam create-user --user-name Terraform

{
    "User": {
        "Path": "/",
        "UserName": "Terraform",
        "UserId": "AIDA6NWV5OXI2RB6ALIBQ",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:user/Terraform",
        "CreateDate": "2022-04-21T17:07:02+00:00"
    }
}


aws --profile admin iam create-access-key --user-name Terraform

{
    "AccessKey": {
        "UserName": "Terraform",
        "AccessKeyId": "...",
        "Status": "Active",
        "SecretAccessKey": "...",
        "CreateDate": "2022-04-21T17:07:27+00:00"
    }
}


aws configure --profile terraform


cat ~/.aws/credentials

[terraform]
aws_access_key_id = ...
aws_secret_access_key = ...


cat <<EOF >assume-role-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${AWS_ACCOUNT_ID}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws --profile admin iam create-role --role-name Terraform-Manage-VPCs --assume-role-policy-document file://assume-role-policy.json
aws --profile admin iam create-role --role-name Terraform-Manage-Subnets --assume-role-policy-document file://assume-role-policy.json
aws --profile admin iam create-role --role-name Terraform-Manage-Keys --assume-role-policy-document file://assume-role-policy.json
aws --profile admin iam create-role --role-name Terraform-Manage-Bastion --assume-role-policy-document file://assume-role-policy.json
aws --profile admin iam create-role --role-name Terraform-Manage-OpenVPN --assume-role-policy-document file://assume-role-policy.json
aws --profile admin iam create-role --role-name Terraform-Manage-Servers --assume-role-policy-document file://assume-role-policy.json
aws --profile admin iam create-role --role-name Terraform-Manage-Lbs --assume-role-policy-document file://assume-role-policy.json
aws --profile admin iam create-role --role-name Terraform-Manage-K8s --assume-role-policy-document file://assume-role-policy.json

aws --profile admin iam create-role --role-name Packer-Build --assume-role-policy-document file://assume-role-policy.json

aws --profile admin iam create-role --role-name EKS-Console --assume-role-policy-document file://assume-role-policy.json


{
    "Role": {
        "Path": "/",
        "RoleName": "Terraform-Manage-VPCs",
        "RoleId": "AROA6NWV5OXI4CRGBS7NX",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-VPCs",
        "CreateDate": "2022-04-21T10:43:22+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "arn:aws:iam::${AWS_ACCOUNT_ID}:root"
                    },
                    "Action": "sts:AssumeRole",
                    "Condition": {
                        "Bool": {
                            "aws:MultiFactorAuthPresent": "true"
                        }
                    }
                }
            ]
        }
    }
}


cat <<EOF >role-policy-manage-vpcs.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AcceptVpcPeeringConnection",
        "ec2:AssociateDhcpOptions",
        "ec2:AssociateVpcCidrBlock",
        "ec2:AttachInternetGateway",
        "ec2:CreateDhcpOptions",
        "ec2:CreateInternetGateway",
        "ec2:CreateTags",
        "ec2:CreateVpc",
        "ec2:CreateVpcPeeringConnection",
        "ec2:DeleteDhcpOptions",
        "ec2:DeleteInternetGateway",
        "ec2:DeleteTags",
        "ec2:DeleteVpc",
        "ec2:DeleteVpcPeeringConnection",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeTags",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeVpcPeeringConnections",
        "ec2:DescribeVpcs",
        "ec2:DetachInternetGateway",
        "ec2:DisassociateVpcCidrBlock",
        "ec2:ModifyVpcAttribute",
        "ec2:ModifyVpcPeeringConnectionOptions",
        "ec2:RejectVpcPeeringConnection"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws --profile admin iam create-policy --policy-name Manage-VPCs --policy-document file://role-policy-manage-vpcs.json

{
    "Policy": {
        "PolicyName": "Manage-VPCs",
        "PolicyId": "ANPA6NWV5OXIUFEEZ5XIK",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-VPCs",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2022-04-22T06:49:21+00:00",
        "UpdateDate": "2022-04-22T06:49:21+00:00"
    }
}


cat <<EOF >role-policy-manage-subnets.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AllocateAddress",
        "ec2:AssignPrivateIpAddresses",
        "ec2:AssociateAddress",
        "ec2:AssociateRouteTable",
        "ec2:AssociateSubnetCidrBlock",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateNatGateway",
        "ec2:CreateNetworkInterface",
        "ec2:CreateRoute",
        "ec2:CreateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSubnet",
        "ec2:CreateTags",
        "ec2:DeleteNatGateway",
        "ec2:DeleteNetworkInterface",
        "ec2:DeleteRoute",
        "ec2:DeleteRouteTable",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSubnet",
        "ec2:DeleteTags",
        "ec2:DescribeAddresses",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeNatGateways",
        "ec2:DescribeNetworkInterfaceAttribute",
        "ec2:DescribeNetworkInterfacePermissions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroupReferences",
        "ec2:DescribeSecurityGroupRules",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DetachNetworkInterface",
        "ec2:DisassociateAddress",
        "ec2:DisassociateRouteTable",
        "ec2:DisassociateSubnetCidrBlock",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:ModifySecurityGroupRules",
        "ec2:ModifySubnetAttribute",
        "ec2:ReleaseAddress",
        "ec2:ReplaceRoute",
        "ec2:ReplaceRouteTableAssociation",
        "ec2:ResetNetworkInterfaceAttribute",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:UnassignPrivateIpAddresses"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws --profile admin iam create-policy --policy-name Manage-Subnets --policy-document file://role-policy-manage-subnets.json

{
    "Policy": {
        "PolicyName": "Manage-Subnets",
        "PolicyId": "ANPA6NWV5OXIWHSZWMJET",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-Subnets",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2022-04-22T06:50:16+00:00",
        "UpdateDate": "2022-04-22T06:50:16+00:00"
    }
}


cat <<EOF >role-policy-manage-keys.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ec2:CreateKeyPair",
              "ec2:DeleteKeyPair",
              "ec2:ImportKeyPair"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
              "ec2:DescribeKeyPairs"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws --profile admin iam create-policy --policy-name Manage-Keys --policy-document file://role-policy-manage-keys.json

{
    "Policy": {
        "PolicyName": "Manage-Keys",
        "PolicyId": "ANPA6NWV5OXIRVVPKY3EY",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-Keys",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2022-04-24T17:10:19+00:00",
        "UpdateDate": "2022-04-24T17:10:19+00:00"
    }
}


cat <<EOF >role-policy-manage-bastion.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteLaunchTemplate",
                "ec2:DeleteSnapshot",
                "ec2:DescribeInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeTags",
                "ec2:DeleteTags",
                "ec2:CreateTags",
                "ec2:DescribeRegions",
                "ec2:RunInstances",
                "ec2:DescribeSnapshots",
                "ec2:StopInstances",
                "ec2:CreateLaunchTemplateVersion",
                "ec2:CreateVolume",
                "ec2:DescribeImages",
                "ec2:DeleteVolume",
                "ec2:CreateLaunchTemplate",
                "ec2:DescribeVolumeStatus",
                "ec2:StartInstances",
                "ec2:DescribeVolumes",
                "ec2:CreateSnapshot",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeInstanceTypes",
                "ec2:DeleteLaunchTemplateVersions",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:DescribeSecurityGroupRules",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:GetLaunchTemplateData",
                "ec2:ModifyLaunchTemplate",
                "ec2:AssociateIamInstanceProfile",
                "ec2:DisassociateIamInstanceProfile",
                "ec2:DescribeInstanceCreditSpecifications",
                "ec2:GetDefaultCreditSpecification",
                "ec2:ModifyDefaultCreditSpecification",
                "ec2:ModifyInstanceCreditSpecification",
                "ec2:ModifyInstanceAttribute",
                "ec2:DescribeNetworkInterfaces",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:ListInstanceProfilesForRole",
                "iam:PassRole",
                "iam:GetRole",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:CreateInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "route53:GetHostedZone",
                "route53:GetChange",
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws --profile admin iam create-policy --policy-name Manage-Bastion --policy-document file://role-policy-manage-bastion.json

{
    "Policy": {
        "PolicyName": "Manage-Bastion",
        "PolicyId": "ANPA6NWV5OXIZ2GOSQKYU",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-Bastion",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2022-04-24T18:10:13+00:00",
        "UpdateDate": "2022-04-24T18:10:13+00:00"
    }
}


cat <<EOF >role-policy-manage-openvpn.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteLaunchTemplate",
                "ec2:DeleteSnapshot",
                "ec2:DescribeInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeTags",
                "ec2:DeleteTags",
                "ec2:CreateTags",
                "ec2:DescribeRegions",
                "ec2:RunInstances",
                "ec2:DescribeSnapshots",
                "ec2:StopInstances",
                "ec2:CreateLaunchTemplateVersion",
                "ec2:CreateVolume",
                "ec2:DescribeImages",
                "ec2:DeleteVolume",
                "ec2:CreateLaunchTemplate",
                "ec2:DescribeVolumeStatus",
                "ec2:StartInstances",
                "ec2:DescribeVolumes",
                "ec2:CreateSnapshot",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeInstanceTypes",
                "ec2:DeleteLaunchTemplateVersions",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:DescribeSecurityGroupRules",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:GetLaunchTemplateData",
                "ec2:ModifyLaunchTemplate",
                "ec2:AssociateIamInstanceProfile",
                "ec2:DisassociateIamInstanceProfile",
                "ec2:DescribeInstanceCreditSpecifications",
                "ec2:GetDefaultCreditSpecification",
                "ec2:ModifyDefaultCreditSpecification",
                "ec2:ModifyInstanceCreditSpecification",
                "ec2:ModifyInstanceAttribute",
                "ec2:DescribeNetworkInterfaces",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:ListInstanceProfilesForRole",
                "iam:PassRole",
                "iam:GetRole",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:CreateInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "route53:GetHostedZone",
                "route53:GetChange",
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
              "s3:ListBucket",
              "s3:GetObject"
            ],
            "Resource": [
               "arn:aws:s3:::nextbreakpoint-openvpn-wip",
               "arn:aws:s3:::nextbreakpoint-openvpn-wip/*"
            ]
        }
    ]
}
EOF

aws --profile admin iam create-policy --policy-name Manage-OpenVPN --policy-document file://role-policy-manage-openvpn.json


cat <<EOF >role-policy-manage-servers.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteLaunchTemplate",
                "ec2:DeleteSnapshot",
                "ec2:DescribeInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeTags",
                "ec2:DeleteTags",
                "ec2:CreateTags",
                "ec2:DescribeRegions",
                "ec2:RunInstances",
                "ec2:DescribeSnapshots",
                "ec2:StopInstances",
                "ec2:CreateLaunchTemplateVersion",
                "ec2:CreateVolume",
                "ec2:DescribeImages",
                "ec2:DeleteVolume",
                "ec2:CreateLaunchTemplate",
                "ec2:DescribeVolumeStatus",
                "ec2:StartInstances",
                "ec2:DescribeVolumes",
                "ec2:CreateSnapshot",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeInstanceTypes",
                "ec2:DeleteLaunchTemplateVersions",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:DescribeSecurityGroupRules",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:GetLaunchTemplateData",
                "ec2:ModifyLaunchTemplate",
                "ec2:AssociateIamInstanceProfile",
                "ec2:DisassociateIamInstanceProfile",
                "ec2:DescribeInstanceCreditSpecifications",
                "ec2:GetDefaultCreditSpecification",
                "ec2:ModifyDefaultCreditSpecification",
                "ec2:ModifyInstanceCreditSpecification",
                "ec2:ModifyInstanceAttribute",
                "ec2:DescribeNetworkInterfaces",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:ListInstanceProfilesForRole",
                "iam:PassRole",
                "iam:GetRole",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:CreateInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "route53:GetHostedZone",
                "route53:GetChange",
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws --profile admin iam create-policy --policy-name Manage-Servers --policy-document file://role-policy-manage-servers.json


cat <<EOF >role-policy-manage-lbs.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:DescribeSecurityGroupRules",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetRulePriorities",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:SetWebAcl",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:RemoveTags",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeleteRule",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:ModifyRule",
                "elasticloadbalancing:DescribeAccountLimits",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:DeleteListener",
                "acm:ListCertificates",
                "acm:ListTagsForCertificate",
                "acm:DescribeCertificate"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws --profile admin iam create-policy --policy-name Manage-Lbs --policy-document file://role-policy-manage-lbs.json

{
    "Policy": {
        "PolicyName": "Manage-Lbs",
        "PolicyId": "ANPA6NWV5OXI4STFOCECZ",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-Lbs",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2022-04-25T20:33:44+00:00",
        "UpdateDate": "2022-04-25T20:33:44+00:00"
    }
}


cat <<EOF >role-policy-manage-k8s.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:DescribeSecurityGroupRules",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeSubnets",
                "ec2:DescribeKeyPairs",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:ListInstanceProfilesForRole",
                "iam:PassRole",
                "iam:GetRole",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:CreateInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:CreateServiceLinkedRole",
                "iam:DeleteServiceLinkedRole",
                "eks:DeleteFargateProfile",
                "eks:DescribeFargateProfile",
                "eks:ListTagsForResource",
                "eks:UpdateAddon",
                "eks:UpdateClusterConfig",
                "eks:DescribeAddon",
                "eks:DescribeNodegroup",
                "eks:ListNodegroups",
                "eks:DisassociateIdentityProviderConfig",
                "eks:RegisterCluster",
                "eks:DeleteCluster",
                "eks:CreateFargateProfile",
                "eks:DescribeIdentityProviderConfig",
                "eks:DeleteNodegroup",
                "eks:AccessKubernetesApi",
                "eks:CreateAddon",
                "eks:UpdateNodegroupConfig",
                "eks:DescribeCluster",
                "eks:ListClusters",
                "eks:UpdateClusterVersion",
                "eks:ListAddons",
                "eks:UpdateNodegroupVersion",
                "eks:AssociateEncryptionConfig",
                "eks:ListUpdates",
                "eks:DescribeAddonVersions",
                "eks:ListIdentityProviderConfigs",
                "eks:CreateCluster",
                "eks:UntagResource",
                "eks:CreateNodegroup",
                "eks:DeregisterCluster",
                "eks:ListFargateProfiles",
                "eks:DeleteAddon",
                "eks:DescribeUpdate",
                "eks:TagResource",
                "eks:AssociateIdentityProviderConfig"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws --profile admin iam create-policy --policy-name Manage-K8s --policy-document file://role-policy-manage-k8s.json


cat <<EOF >role-policy-build-ami.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteLaunchTemplate",
                "ec2:DeleteSnapshot",
                "ec2:DescribeInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeTags",
                "ec2:DeleteTags",
                "ec2:CreateTags",
                "ec2:DescribeRegions",
                "ec2:RunInstances",
                "ec2:DescribeSnapshots",
                "ec2:StopInstances",
                "ec2:CreateLaunchTemplateVersion",
                "ec2:CreateVolume",
                "ec2:DescribeImages",
                "ec2:DeleteVolume",
                "ec2:CreateLaunchTemplate",
                "ec2:DescribeVolumeStatus",
                "ec2:StartInstances",
                "ec2:DescribeVolumes",
                "ec2:CreateSnapshot",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeInstanceTypes",
                "ec2:DeleteLaunchTemplateVersions",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:DescribeSecurityGroupRules",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:GetLaunchTemplateData",
                "ec2:ModifyLaunchTemplate",
                "ec2:AssociateIamInstanceProfile",
                "ec2:DisassociateIamInstanceProfile",
                "ec2:DescribeInstanceCreditSpecifications",
                "ec2:GetDefaultCreditSpecification",
                "ec2:ModifyDefaultCreditSpecification",
                "ec2:ModifyInstanceCreditSpecification",
                "ec2:ModifyInstanceAttribute",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeSubnets",
                "ec2:CreateImage",
                "ec2:CreateKeyPair",
                "ec2:DeleteKeyPair",
                "ec2:ImportKeyPair"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws --profile admin iam create-policy --policy-name Build-AMI --policy-document file://role-policy-build-ami.json


cat <<EOF > eks-console-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles",
                "eks:ListClusters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:ListFargateProfiles",
                "eks:DescribeNodegroup",
                "eks:DescribeUpdate",
                "eks:AccessKubernetesApi",
                "eks:ListNodegroups",
                "eks:ListUpdates",
                "eks:ListAddons",
                "eks:DescribeAddonVersions",
                "eks:ListIdentityProviderConfigs",
                "eks:DescribeCluster"
            ],
            "Resource": "arn:aws:eks:eu-west-2:${AWS_ACCOUNT_ID}:cluster/*"
        },
        {
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": "arn:aws:ssm:*:${AWS_ACCOUNT_ID}:parameter/*"
        }
    ]
}
EOF

aws --profile admin iam create-policy --policy-name EKS-Console --policy-document file://eks-console-policy.json




aws --profile admin iam attach-role-policy --role-name Terraform-Manage-VPCs --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-VPCs
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-Subnets --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-Subnets
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-Keys --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-Keys
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-Bastion --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-Bastion
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-OpenVPN --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-OpenVPN
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-Servers --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-Servers
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-Lbs --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-Lbs
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-K8s --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Manage-K8s

aws --profile admin iam attach-role-policy --role-name Packer-Build --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Build-AMI

aws --profile admin iam attach-role-policy --role-name EKS-Console --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/EKS-Console


cat <<EOF >role-policy-update-terraform-state.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::nextbreakpoint-terraform-wip"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::nextbreakpoint-terraform-wip/*"]
    }
  ]
}
EOF

aws --profile admin iam create-policy --policy-name Update-Terraform-State --policy-document file://role-policy-update-terraform-state.json

{
    "Policy": {
        "PolicyName": "Update-Terraform-State",
        "PolicyId": "ANPA6NWV5OXIWRQDNF4M2",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Update-Terraform-State",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2022-04-22T07:46:21+00:00",
        "UpdateDate": "2022-04-22T07:46:21+00:00"
    }
}

aws --profile admin iam attach-role-policy --role-name Terraform-Manage-VPCs --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Update-Terraform-State
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-Subnets --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Update-Terraform-State
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-Keys --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Update-Terraform-State
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-Bastion --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Update-Terraform-State
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-OpenVPN --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Update-Terraform-State
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-Servers --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Update-Terraform-State
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-Lbs --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Update-Terraform-State
aws --profile admin iam attach-role-policy --role-name Terraform-Manage-K8s --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Update-Terraform-State



aws --profile admin iam create-group --group-name Terraform
aws --profile admin iam create-group --group-name Packer
aws --profile admin iam create-group --group-name Platform

{
    "Group": {
        "Path": "/",
        "GroupName": "Terraform",
        "GroupId": "AGPA6NWV5OXIU7VAA7KWM",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:group/Terraform",
        "CreateDate": "2022-04-22T08:08:16+00:00"
    }
}


cat <<EOF >assume-role-terraform-manage-vpcs.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-VPCs"
  }
}
EOF

aws --profile admin iam put-group-policy --group-name Terraform --policy-name Assume-Role-Terraform-Manage-VPCs --policy-document file://assume-role-terraform-manage-vpcs.json


cat <<EOF >assume-role-terraform-manage-subnets.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-Subnets"
  }
}
EOF

aws --profile admin iam put-group-policy --group-name Terraform --policy-name Assume-Role-Terraform-Manage-Subnets --policy-document file://assume-role-terraform-manage-subnets.json


cat <<EOF >assume-role-terraform-manage-keys.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-Keys"
  }
}
EOF

aws --profile admin iam put-group-policy --group-name Terraform --policy-name Assume-Role-Terraform-Manage-Keys --policy-document file://assume-role-terraform-manage-keys.json


cat <<EOF >assume-role-terraform-manage-bastion.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-Bastion"
  }
}
EOF

aws --profile admin iam put-group-policy --group-name Terraform --policy-name Assume-Role-Terraform-Manage-Bastion --policy-document file://assume-role-terraform-manage-bastion.json


cat <<EOF >assume-role-terraform-manage-openvpn.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-OpenVPN"
  }
}
EOF

aws --profile admin iam put-group-policy --group-name Terraform --policy-name Assume-Role-Terraform-Manage-OpenVPN --policy-document file://assume-role-terraform-manage-openvpn.json


cat <<EOF >assume-role-terraform-manage-servers.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-Servers"
  }
}
EOF

aws --profile admin iam put-group-policy --group-name Terraform --policy-name Assume-Role-Terraform-Manage-Servers --policy-document file://assume-role-terraform-manage-servers.json


cat <<EOF >assume-role-terraform-manage-lbs.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-Lbs"
  }
}
EOF

aws --profile admin iam put-group-policy --group-name Terraform --policy-name Assume-Role-Terraform-Manage-Lbs --policy-document file://assume-role-terraform-manage-lbs.json


cat <<EOF >assume-role-terraform-manage-k8s.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-K8s"
  }
}
EOF

aws --profile admin iam put-group-policy --group-name Terraform --policy-name Assume-Role-Terraform-Manage-K8s --policy-document file://assume-role-terraform-manage-k8s.json


cat <<EOF >assume-role-packer-build.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/Packer-Build"
  }
}
EOF

aws --profile admin iam put-group-policy --group-name Packer --policy-name Assume-Role-Packer-Build --policy-document file://assume-role-packer-build.json



cat <<EOF >assume-role-eks-console.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/EKS-Console"
  }
}
EOF

aws --profile admin iam put-group-policy --group-name Platform --policy-name Assume-Role-EKS-Console --policy-document file://assume-role-eks-console.json



aws --profile admin iam add-user-to-group --user-name Terraform --group-name Terraform
aws --profile admin iam add-user-to-group --user-name Terraform --group-name Packer


aws --profile terraform sts assume-role --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-VPCs --role-session-name Terraform-Manage-VPCs --duration-seconds=3600

{
    "Credentials": {
        "AccessKeyId": "..",
        "SecretAccessKey": "...",
        "SessionToken": "...",
        "Expiration": "2022-04-21T12:33:11+00:00"
    },
    "AssumedRoleUser": {
        "AssumedRoleId": "AROA6NWV5OXI4CRGBS7NX:Terraform-Manage-VPCs",
        "Arn": "arn:aws:sts::${AWS_ACCOUNT_ID}:assumed-role/Terraform-Manage-VPCs/Terraform-Manage-VPCs"
    }
}


$(aws --profile terraform sts assume-role --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/Terraform-Manage-VPCs --role-session-name Terraform-Manage-VPCs --duration-seconds=3600 | jq --raw-output '"export AWS_ACCESS_KEY_ID=" + .Credentials.AccessKeyId + "\nexport AWS_SECRET_ACCESS_KEY=" + .Credentials.SecretAccessKey + "\nexport AWS_SESSION_TOKEN=" + .Credentials.SessionToken')


$(./assume-role.sh --account=$AWS_ACCOUNT_ID --role=Terraform-Manage-VPCs)
$(./assume-role.sh --account=$AWS_ACCOUNT_ID --role=Terraform-Manage-Subnets)
$(./assume-role.sh --account=$AWS_ACCOUNT_ID --role=Terraform-Manage-Keys)
$(./assume-role.sh --account=$AWS_ACCOUNT_ID --role=Terraform-Manage-Bastion)
$(./assume-role.sh --account=$AWS_ACCOUNT_ID --role=Terraform-Manage-OpenVPN)
$(./assume-role.sh --account=$AWS_ACCOUNT_ID --role=Terraform-Manage-Servers)
$(./assume-role.sh --account=$AWS_ACCOUNT_ID --role=Terraform-Manage-Lbs)
$(./assume-role.sh --account=$AWS_ACCOUNT_ID --role=Terraform-Manage-K8s)

$(./assume-role.sh --account=$AWS_ACCOUNT_ID --role=Packer-Build)





$(./assume-role.sh --account=$AWS_ACCOUNT_ID --role=Terraform-Manage-VPCs)

aws sts get-caller-identity

{
    "UserId": "AROA6NWV5OXI4CRGBS7NX:Terraform-Manage-VPCs",
    "Account": "${AWS_ACCOUNT_ID}",
    "Arn": "arn:aws:sts::${AWS_ACCOUNT_ID}:assumed-role/Terraform-Manage-VPCs/Terraform-Manage-VPCs"
}

aws ec2 describe-vpcs   




aws --profile admin iam update-account-password-policy --minimum-password-length 8 --require-numbers --require-uppercase-characters --require-lowercase-characters --require-symbols --max-password-age 30


aws --profile admin iam create-user --user-name Andrea

{
    "User": {
        "Path": "/",
        "UserName": "Andrea",
        "UserId": "AIDA6NWV5OXIWPWSPXESN",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:user/Andrea",
        "CreateDate": "2022-04-22T06:13:28+00:00"
    }
}


aws --profile admin iam create-login-profile --user-name Andrea --password-reset-required --password password

{
    "LoginProfile": {
        "UserName": "Andrea",
        "CreateDate": "2022-04-22T06:34:19+00:00",
        "PasswordResetRequired": true
    }
}


aws --profile admin iam create-virtual-mfa-device --virtual-mfa-device-name andrea-mfa-device --outfile QRCode.png --bootstrap-method QRCodePNG

{
    "VirtualMFADevice": {
        "SerialNumber": "arn:aws:iam::${AWS_ACCOUNT_ID}:mfa/andrea-mfa-device"
    }
}


aws --profile admin iam enable-mfa-device --user-name Andrea --serial-number arn:aws:iam::${AWS_ACCOUNT_ID}:mfa/andrea-mfa-device --authentication-code1 299084 --authentication-code2 067305


aws --profile admin iam create-group --group-name Administrators

{
    "Group": {
        "Path": "/",
        "GroupName": "Administrators",
        "GroupId": "AGPA6NWV5OXI6WHN2HKMB",
        "Arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:group/Administrators",
        "CreateDate": "2022-04-22T06:21:33+00:00"
    }
}


aws --profile admin iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
aws --profile admin iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess
aws --profile admin iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/AmazonVPCReadOnlyAccess
aws --profile admin iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws --profile admin iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::aws:policy/IAMAccessAnalyzerReadOnlyAccess
aws --profile admin iam attach-group-policy --group-name Administrators --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/EKS-Console

aws --profile admin iam add-user-to-group --user-name Andrea --group-name Administrators


open https://${AWS_ACCOUNT_ID}.signin.aws.amazon.com/console



BASTION_SUBNET=$(terraform output -json bastion-public-subnet-a-id | jq -r '.')
packer build --var-file=../vars.json --var aws_subnet_id=${BASTION_SUBNET} packer.json



aws --profile admin iam update-access-key --access-key-id $ACCESS_KEY_ID --status Inactive --user-name Admin


aws --profile admin iam create-user --user-name Andrea.Medeghini
aws --profile admin iam create-access-key --user-name Andrea.Medeghini
aws --profile admin iam add-user-to-group --user-name Andrea.Medeghini --group-name Platform
$(./assume-role.sh --profile=andrea.medeghini --account=$AWS_ACCOUNT_ID --role=EKS-Console)

aws eks update-kubeconfig --region eu-west-2 --name prod-green-k8s --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/EKS-Console



aws --profile admin s3 mb s3://nextbreakpoint-terraform-wip --region eu-west-2
aws --profile admin s3 mb s3://nextbreakpoint-openvpn-wip --region eu-west-2
aws --profile admin s3 mb s3://nextbreakpoint-servers-wip --region eu-west-2


tfenv install 1.1.9
tfenv use 1.1.9


cat <<EOF >vpcs.json
{
    "environment": "prod",
    "colour": "green",
    "aws_network_vpc_cidr": "172.32.0.0/16",
    "aws_bastion_vpc_cidr": "172.33.0.0/16",
    "aws_openvpn_vpc_cidr": "172.34.0.0/16"
}
EOF

cat <<EOF >subnets.json
{
    "environment": "prod",
    "colour": "green",
    "workspace": "integration-green",
    "aws_platform_public_subnet_cidr_a": "172.32.0.0/24",
    "aws_platform_public_subnet_cidr_b": "172.32.2.0/24",
    "aws_platform_public_subnet_cidr_c": "172.32.4.0/24",
    "aws_platform_private_subnet_cidr_a": "172.32.1.0/24",
    "aws_platform_private_subnet_cidr_b": "172.32.3.0/24",
    "aws_platform_private_subnet_cidr_c": "172.32.5.0/24",
    "aws_bastion_subnet_cidr_a": "172.33.0.0/24",
    "aws_bastion_subnet_cidr_b": "172.33.2.0/24",
    "aws_bastion_subnet_cidr_c": "172.33.4.0/24",
    "aws_openvpn_subnet_cidr_a": "172.34.0.0/24",
    "aws_openvpn_subnet_cidr_b": "172.34.2.0/24",
    "aws_openvpn_subnet_cidr_c": "172.34.4.0/24",
    "enable_nat_gateways": true
}
EOF

cat <<EOF >keys.json
{
    "environment": "prod",
    "colour": "green",
    "keys_path": "keys"
}
EOF

cat <<EOF >bastion.json
{
    "environment": "prod",
    "colour": "green",
    "workspace": "integration-green",
    "hosted_zone_id": "Z1XAF7NWT4WCJG",
    "hosted_zone_name": "nextbreakpoint.com",
    "bastion": true
}
EOF

cat <<EOF >openvpn.json
{
    "environment": "prod",
    "colour": "green",
    "workspace": "integration-green",
    "hosted_zone_id": "Z1XAF7NWT4WCJG",
    "hosted_zone_name": "nextbreakpoint.com",
    "base_version": "1.0",
    "account_id": "${AWS_ACCOUNT_ID}",
    "secrets_bucket_name": "nextbreakpoint-openvpn-wip",
    "openvpn_key_password": "password",
    "openvpn_keystore_password": "password",
    "openvpn_truststore_password": "password"
}
EOF

cat <<EOF >servers.json
{
    "environment": "prod",
    "colour": "green",
    "workspace": "integration-green",
    "hosted_zone_id": "Z1XAF7NWT4WCJG",
    "hosted_zone_name": "nextbreakpoint.com",
    "base_version": "1.0",
    "account_id": "${AWS_ACCOUNT_ID}",
    "secrets_bucket_name": "nextbreakpoint-servers-wip"
}
EOF

cat <<EOF >k8s.json
{
    "environment": "prod",
    "colour": "green",
    "workspace": "integration-green",
    "hosted_zone_id": "Z1XAF7NWT4WCJG",
    "hosted_zone_name": "nextbreakpoint.com"
}
EOF


ssh-keygen -b 2048 -t rsa -N "" -f keys/prod-green-openvpn.pem
ssh-keygen -b 2048 -t rsa -N "" -f keys/prod-green-bastion.pem
ssh-keygen -b 2048 -t rsa -N "" -f keys/prod-green-server.pem
ssh-keygen -b 2048 -t ed25519 -N "" -f keys/prod-green-packer.pem


aws --profile admin acm request-certificate --domain-name '*.nextbreakpoint.com' --validation-method DNS    
aws --profile admin acm request-certificate --domain-name '*.internal.nextbreakpoint.com' --validation-method DNS    


ssh -i keys/prod-green-bastion.pem ubuntu@prod-green-bastion.nextbreakpoint.com


aws --profile admin s3 cp s3://nextbreakpoint-openvpn-wip/client.ovpn .
aws --profile admin s3 cp s3://nextbreakpoint-openvpn-wip/client.conf .


aws --profile admin iam get-user --user-name Admin | jq -r '.User.UserId'

aws --profile admin iam get-role --role-name Terraform-Manage-VPCs | jq -r '.Role.RoleId'
aws --profile admin iam get-role --role-name Terraform-Manage-Subnets | jq -r '.Role.RoleId'
aws --profile admin iam get-role --role-name Terraform-Manage-Keys | jq -r '.Role.RoleId'
aws --profile admin iam get-role --role-name Terraform-Manage-Lbs | jq -r '.Role.RoleId'
aws --profile admin iam get-role --role-name Terraform-Manage-Bastion | jq -r '.Role.RoleId'
aws --profile admin iam get-role --role-name Terraform-Manage-OpenVPN | jq -r '.Role.RoleId'
aws --profile admin iam get-role --role-name Terraform-Manage-Servers | jq -r '.Role.RoleId'
aws --profile admin iam get-role --role-name Terraform-Manage-K8s | jq -r '.Role.RoleId'


cat <<EOF >bucket-openvpn-deny-access.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
         "arn:aws:s3:::nextbreakpoint-openvpn-wip",
         "arn:aws:s3:::nextbreakpoint-openvpn-wip/*"
      ],
      "Condition": {
        "StringNotLike": {
          "aws:userId": [
            "AROA6NWV5OXI2ID2PROVL:*",
            "AIDA6NWV5OXIRIRKQ6FYM",
            "${AWS_ACCOUNT_ID}"
          ]
        }
      }
    }
  ]
}
EOF

aws --profile admin s3api put-bucket-policy --bucket nextbreakpoint-openvpn-wip --policy file://bucket-openvpn-deny-access.json


cat <<EOF >bucket-terraform-deny-access.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
         "arn:aws:s3:::nextbreakpoint-terraform-wip",
         "arn:aws:s3:::nextbreakpoint-terraform-wip/*"
      ],
      "Condition": {
        "StringNotLike": {
          "aws:userId": [
            "AROA6NWV5OXIRN6QAYDZT:*",
            "AROA6NWV5OXI7W7TEMWI6:*",
            "AROA6NWV5OXIZRLFNVACE:*",
            "AROA6NWV5OXI6NW43MLUV:*",
            "AROA6NWV5OXIWJGWWLA2P:*",
            "AROA6NWV5OXI2ID2PROVL:*",
            "AROA6NWV5OXIY4SKANOLI:*",
            "AROA6NWV5OXIUYWLFEDFR:*",
            "AIDA6NWV5OXIRIRKQ6FYM",
            "${AWS_ACCOUNT_ID}"
          ]
        }
      }
    }
  ]
}
EOF

aws --profile admin s3api put-bucket-policy --bucket nextbreakpoint-terraform-wip --policy file://bucket-terraform-deny-access.json



cat <<EOF > eks-readonly-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles",
                "eks:ListClusters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:ListFargateProfiles",
                "eks:DescribeNodegroup",
                "eks:DescribeUpdate",
                "eks:AccessKubernetesApi",
                "eks:ListNodegroups",
                "eks:ListUpdates",
                "eks:ListAddons",
                "eks:DescribeAddonVersions",
                "eks:ListIdentityProviderConfigs",
                "eks:DescribeCluster"
            ],
            "Resource": "arn:aws:eks:eu-west-2:${AWS_ACCOUNT_ID}:cluster/*"
        },
        {
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": "arn:aws:ssm:*:${AWS_ACCOUNT_ID}:parameter/*"
        }
    ]
}
EOF

aws --profile admin iam put-user-policy --user-name Andrea --policy-name EKS-ReadOnly --policy-document file://eks-readonly-policy.json


cat <<EOF >decode-authorizaton-message.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "decodepolicy",
      "Effect": "Allow",
      "Action": "sts:DecodeAuthorizationMessage",
      "Resource": "*"
    }
  ]
}
EOF

aws --profile admin iam put-user-policy --user-name Admin --policy-name DecodeAuthorizationMessage --policy-document file://decode-authorizaton-message.json

aws --profile admin s3api put-public-access-block --bucket nextbreakpoint-openvpn-wip --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

aws --profile admin s3api put-public-access-block --bucket nextbreakpoint-terraform-wip --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"


aws --profile admin sts decode-authorization-message --encoded-message $MESSAGE | jq -r '.DecodedMessage' | jq


terraform init
terraform workspace new integration-green
terraform plan --var-file=keys.json -out tfplan
terraform plan --var-file=vpcs.json -out tfplan
terraform plan --var-file=subnets.json -out tfplan
terraform plan --var-file=bastion.json -out tfplan
terraform plan --var-file=openvpn.json -out tfplan
terraform plan --var-file=servers.json -out tfplan
terraform plan --var-file=lbs.json -out tfplan
terraform plan --var-file=k8s.json -out tfplan
terraform apply tfplan
terraform destroy --var-file=keys.json
terraform destroy --var-file=vpcs.json
terraform destroy --var-file=subnets.json
terraform destroy --var-file=bastion.json
terraform destroy --var-file=openvpn.json
terraform destroy --var-file=servers.json
terraform destroy --var-file=lbs.json
terraform destroy --var-file=k8s.json


aws eks update-kubeconfig --region eu-west-2 --name prod-green-k8s


kubectl create ns test

cat <<EOF > namespace-test-role.yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: k8s-test-role
  namespace: test
rules:
  - apiGroups:
      - ""
      - "apps"
      - "batch"
      - "extensions"
    resources:
      - "configmaps"
      - "cronjobs"
      - "deployments"
      - "events"
      - "ingresses"
      - "jobs"
      - "pods"
      - "pods/attach"
      - "pods/exec"
      - "pods/log"
      - "pods/portforward"
      - "secrets"
      - "services"
    verbs:
      - "create"
      - "delete"
      - "describe"
      - "get"
      - "list"
      - "patch"
      - "update"
EOF

kubectl apply -f namespace-test-role.yaml

cat <<EOF > namespace-test-rolebinding.yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: k8s-test-rolebinding
  namespace: test
subjects:
- kind: User
  name: k8s-test-user
roleRef:
  kind: Role
  name: k8s-test-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f namespace-test-rolebinding.yaml


eksctl create iamidentitymapping --cluster prod-green-k8s --region=eu-west-2 --arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/EKS-Console --username k8s-test-user


kubectl apply -f https://s3.us-west-2.amazonaws.com/amazon-eks/docs/eks-console-full-access.yaml

eksctl get iamidentitymapping --cluster prod-green-k8s --region=eu-west-2

eksctl create iamidentitymapping --cluster prod-green-k8s --region=eu-west-2 --arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/EKS-Console --group eks-console-dashboard-full-access-group --no-duplicate-arns

eksctl create iamidentitymapping --cluster prod-green-k8s --region=eu-west-2 --arn arn:aws:iam::${AWS_ACCOUNT_ID}:user/Andrea --group eks-console-dashboard-restricted-access-group --no-duplicate-arns

eksctl create iamidentitymapping --cluster prod-green-k8s --region=eu-west-2 --arn arn:aws:iam::${AWS_ACCOUNT_ID}:user/Andrea --group eks-console-dashboard-full-access-group --no-duplicate-arns
