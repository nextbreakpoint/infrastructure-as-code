data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "decode-authorization-message" {
  name   = "Decode-Authorization-Message"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:DecodeAuthorizationMessage"
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

resource "aws_iam_policy" "manage-policies" {
  name   = "Manage-Policies"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:ListPolicyVersions",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion"
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

resource "aws_iam_policy" "manage-groups" {
  name   = "Manage-Groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetGroup",
          "iam:CreateGroup",
          "iam:DeleteGroup",
          "iam:UpdateGroup",
          "iam:GetGroupPolicy",
          "iam:PutGroupPolicy",
          "iam:DeleteGroupPolicy"
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

resource "aws_iam_policy" "manage-roles" {
  name   = "Manage-Roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy"
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

resource "aws_iam_policy" "manage-terraform-state" {
  name   = "Manage-Terraform-State"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_bucket_name}",
          "arn:aws:s3:::${var.terraform_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.terraform_bucket_name}"
        ]
      }
    ]
  })

  tags = {
    Environment = "${var.environment}"
    Colour      = "${var.colour}"
  }
}

resource "aws_iam_role" "terraform-manage-security" {
  name = "Terraform-Manage-Security"

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

resource "aws_iam_role_policy_attachment" "terraform-manage-iam-policies" {
  role       = aws_iam_role.terraform-manage-security.name
  policy_arn = aws_iam_policy.manage-policies.arn
}

resource "aws_iam_role_policy_attachment" "terraform-manage-iam-groups" {
  role       = aws_iam_role.terraform-manage-security.name
  policy_arn = aws_iam_policy.manage-groups.arn
}

resource "aws_iam_role_policy_attachment" "terraform-manage-iam-roles" {
  role       = aws_iam_role.terraform-manage-security.name
  policy_arn = aws_iam_policy.manage-roles.arn
}

resource "aws_iam_role_policy_attachment" "terraform-manage-iam-state" {
  role       = aws_iam_role.terraform-manage-security.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Manage-Terraform-State"
}

resource "aws_iam_group" "security" {
  name = "Terraform-Security"
}

resource "aws_iam_group_policy" "terraform-manage-security" {
  name  = "Terraform-Manage-Security"
  group = aws_iam_group.security.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform-Manage-Security"
        ]
      }
    ]
  })
}
