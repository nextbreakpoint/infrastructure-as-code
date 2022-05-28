data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "manage-vpcs" {
  name   = "Manage-VPCs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeVpcs",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:DescribeVpcAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:AssociateVpcCidrBlock",
          "ec2:DisassociateVpcCidrBlock",
          "ec2:DescribeInternetGateways",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DescribeDhcpOptions",
          "ec2:CreateDhcpOptions",
          "ec2:DeleteDhcpOptions",
          "ec2:AssociateDhcpOptions",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:CreateVpcPeeringConnection",
          "ec2:DeleteVpcPeeringConnection",
          "ec2:AcceptVpcPeeringConnection",
          "ec2:RejectVpcPeeringConnection",
          "ec2:ModifyVpcPeeringConnectionOptions"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_policy" "manage-subnets" {
  name   = "Manage-Subnets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeSubnets",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:DescribeRouteTables",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:ReplaceRoute",
          "ec2:DescribeAddresses",
          "ec2:AssociateAddress",
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeSecurityGroupReferences",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeNetworkInterfaces",
          "ec2:ModifySubnetAttribute",
          "ec2:DescribeNatGateways",
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_policy" "manage-keys" {
  name   = "Manage-Keys"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeKeyPairs",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:ImportKeyPair"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_policy" "manage-machines" {
  name   = "Manage-Machines"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeRegions",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:ModifyLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:GetLaunchTemplateData",
          "ec2:DescribeSnapshots",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeVolumes",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:DescribeVolumeStatus",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:DeleteLaunchTemplateVersions",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeSecurityGroupReferences",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeInstanceCreditSpecifications",
          "ec2:GetDefaultCreditSpecification",
          "ec2:ModifyDefaultCreditSpecification",
          "ec2:ModifyInstanceCreditSpecification",
          "ec2:AssociateIamInstanceProfile",
          "ec2:DisassociateIamInstanceProfile",
          "ec2:DescribeNetworkInterfaces",
          "iam:GetRole",
          "iam:PassRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "route53:GetHostedZone",
          "route53:GetChange",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_policy" "manage-lbs" {
  name   = "Manage-LBs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeSecurityGroupReferences",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeNetworkInterfaces",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:SetRulePriorities",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeAccountLimits",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate",
          "acm:DescribeCertificate",
          "acm:GetCertificate"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_policy" "manage-k8s" {
  name   = "Manage-K8s"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
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
          "iam:GetRole",
          "iam:PassRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "eks:ListClusters",
          "eks:DescribeCluster",
          "eks:CreateCluster",
          "eks:DeleteCluster",
          "eks:RegisterCluster",
          "eks:DeregisterCluster",
          "eks:ListAddons",
          "eks:DescribeAddon",
          "eks:CreateAddon",
          "eks:UpdateAddon",
          "eks:DeleteAddon",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:CreateNodegroup",
          "eks:DeleteNodegroup",
          "eks:UpdateNodegroupVersion",
          "eks:ListUpdates",
          "eks:DescribeUpdate",
          "eks:AccessKubernetesApi",
          "eks:UpdateClusterVersion",
          "eks:UpdateClusterConfig",
          "eks:UpdateNodegroupConfig",
          "eks:AssociateEncryptionConfig",
          "eks:ListIdentityProviderConfigs",
          "eks:DescribeIdentityProviderConfig",
          "eks:AssociateIdentityProviderConfig",
          "eks:DisassociateIdentityProviderConfig",
          "eks:DescribeAddonVersions",
          "eks:ListTagsForResource",
          "eks:TagResource",
          "eks:UntagResource",
          "ec2:DescribeSubnets",
          "ec2:DescribeKeyPairs"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_policy" "manage-amis" {
  name   = "Manage-AMIs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:DeleteTags",
          "ec2:CreateTags",
          "ec2:DescribeInstances",
          "ec2:RunInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceAttribute",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeRegions",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeSnapshots",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeImages",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:CreateLaunchTemplate",
          "ec2:ModifyLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:GetLaunchTemplateData",
          "ec2:DeleteLaunchTemplateVersions",
          "ec2:DescribeSecurityGroupReferences",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroupRules",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AssociateIamInstanceProfile",
          "ec2:DisassociateIamInstanceProfile",
          "ec2:DescribeInstanceCreditSpecifications",
          "ec2:GetDefaultCreditSpecification",
          "ec2:ModifyDefaultCreditSpecification",
          "ec2:ModifyInstanceCreditSpecification",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:CreateImage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_policy" "developers" {
  name   = "Developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = [
          "arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:cluster/${var.environment}-${var.colour}-${var.cluster_name}"
        ]
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_policy" "eksconsole" {
  name   = "EKS-Console"

  policy = jsonencode({
    Version = "2012-10-17"
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
            "Resource": [
              "arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:cluster/${var.environment}-${var.colour}-${var.cluster_name}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": [
              "arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:parameter/*"
            ]
        }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role" "terraform-manage-networks" {
  name = "Terraform-Manage-Networks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role" "terraform-manage-servers" {
  name = "Terraform-Manage-Servers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role" "terraform-manage-clusters" {
  name = "Terraform-Manage-Clusters"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role" "packer-build-images" {
  name = "Packer-Build-Images"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role" "developers" {
  name = "Developers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role_policy_attachment" "terraform-manage-networks-vpcs" {
  role       = aws_iam_role.terraform-manage-networks.name
  policy_arn = aws_iam_policy.manage-vpcs.arn
}

resource "aws_iam_role_policy_attachment" "terraform-manage-networks-subnets" {
  role       = aws_iam_role.terraform-manage-networks.name
  policy_arn = aws_iam_policy.manage-subnets.arn
}

resource "aws_iam_role_policy_attachment" "terraform-manage-networks-state" {
  role       = aws_iam_role.terraform-manage-networks.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Manage-Terraform-State"
}

resource "aws_iam_role_policy_attachment" "terraform-manage-servers-keys" {
  role       = aws_iam_role.terraform-manage-servers.name
  policy_arn = aws_iam_policy.manage-keys.arn
}

resource "aws_iam_role_policy_attachment" "terraform-manage-servers-ec2" {
  role       = aws_iam_role.terraform-manage-servers.name
  policy_arn = aws_iam_policy.manage-machines.arn
}

resource "aws_iam_role_policy_attachment" "terraform-manage-servers-state" {
  role       = aws_iam_role.terraform-manage-servers.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Manage-Terraform-State"
}

resource "aws_iam_role_policy_attachment" "terraform-manage-clusters-k8s" {
  role       = aws_iam_role.terraform-manage-clusters.name
  policy_arn = aws_iam_policy.manage-k8s.arn
}

resource "aws_iam_role_policy_attachment" "terraform-manage-clusters-lbs" {
  role       = aws_iam_role.terraform-manage-clusters.name
  policy_arn = aws_iam_policy.manage-lbs.arn
}

resource "aws_iam_role_policy_attachment" "terraform-manage-clusters-state" {
  role       = aws_iam_role.terraform-manage-clusters.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Manage-Terraform-State"
}

resource "aws_iam_role_policy_attachment" "packer-build-images" {
  role       = aws_iam_role.packer-build-images.name
  policy_arn = aws_iam_policy.manage-amis.arn
}

resource "aws_iam_role_policy_attachment" "developers" {
  role       = aws_iam_role.developers.name
  policy_arn = aws_iam_policy.developers.arn
}

resource "aws_iam_group" "networks" {
  name = "Terraform-Networks"
}

resource "aws_iam_group" "servers" {
  name = "Terraform-Servers"
}

resource "aws_iam_group" "clusters" {
  name = "Terraform-Clusters"
}

resource "aws_iam_group" "build" {
  name = "Packer-Build"
}

resource "aws_iam_group" "developers" {
  name = "Developers"
}

resource "aws_iam_group_policy" "terraform-manage-networks" {
  name  = "Terraform-Manage-Networks"
  group = aws_iam_group.networks.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform-Manage-Networks"
        ]
      }
    ]
  })
}

resource "aws_iam_group_policy" "terraform-manage-servers" {
  name  = "Terraform-Manage-Servers"
  group = aws_iam_group.servers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform-Manage-Servers"
        ]
      }
    ]
  })
}

resource "aws_iam_group_policy" "terraform-manage-clusters" {
  name  = "Terraform-Manage-Clusters"
  group = aws_iam_group.clusters.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform-Manage-Clusters"
        ]
      }
    ]
  })
}

resource "aws_iam_group_policy" "packer-build-images" {
  name  = "Packer-Build-Images"
  group = aws_iam_group.build.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Packer-Build-Images"
        ]
      }
    ]
  })
}

resource "aws_iam_group_policy" "developers" {
  name  = "Developers"
  group = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Developers"
        ]
      }
    ]
  })
}
