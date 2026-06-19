# Step 1: Setup Github as an OIDC provider in AWS
resource "aws_iam_openid_connect_provider" "github_oidc_provider" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = [ "sts.amazonaws.com" ]
    # No thumbprint is needed for github; AWS validates github's identity through its trusted CA list
}

# Step 2: Create an IAM role for dev environment that github actions can assume via OIDC
resource "aws_iam_role" "dev_oidc_iam_role" {
    name = "github-aws-dev-oidc-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
            Federated = aws_iam_openid_connect_provider.github_oidc_provider.arn
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
            StringEquals = {
                # Lock down to specific repository
                "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            }
            StringLike = {
                # Only your repo can assume this role
                "token.actions.githubusercontent.com:sub" = "repo:Jasleenkaurnotay/aws-ecs-platform-gitops:*"
            }
            }
          },
        ]
    })
}

# Step 3: Attach AWS managed IAM policies to above defined dev IAM role - gives access for terraform to create infra in AWS 
resource "aws_iam_role_policy_attachment" "dev_github_actions_admin" {
  role       = aws_iam_role.dev_oidc_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Step 4: Create an IAM role for prod environment that github actions can assume via OIDC
resource "aws_iam_role" "prod_oidc_iam_role" {
    name = "github-aws-prod-oidc-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
            Federated = aws_iam_openid_connect_provider.github_oidc_provider.arn
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
            StringEquals = {
                # Lock down to specific repository
                "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            }
            StringLike = {
                # Only your repo can assume this role
                "token.actions.githubusercontent.com:sub" = "repo:Jasleenkaurnotay/aws-ecs-platform-gitops:*"
            }
            }
          },
        ]
    })
}

# Step 5: Attach AWS managed IAM policies to above defined prod IAM role, including access to create and delete infra resources via terraform
resource "aws_iam_role_policy_attachment" "prod_github_actions_admin" {
  role       = aws_iam_role.prod_oidc_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}