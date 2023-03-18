provider "aws" {
}

resource "random_id" "id" {
  byte_length = 8
}

resource "aws_appsync_graphql_api" "appsync_cognito_only" {
  name                = "cognito-only"
  schema              = <<EOF

type Outer {
	scalar: String
@aws_auth(cognito_groups: ["admin"])

	inner: Inner
@aws_auth(cognito_groups: ["admin"])
}

type Inner {
	inner_scalar: String
@aws_auth(cognito_groups: ["admin"])
}

type Query {
	query_scalar: String
@aws_auth(cognito_groups: ["admin"])
	outer: Outer
@aws_auth
}
EOF
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  user_pool_config {
    default_action = "ALLOW"
    user_pool_id   = aws_cognito_user_pool.pool.id
  }
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = "ALL"
  }
}

resource "aws_appsync_graphql_api" "appsync_cognito_with_iam" {
  name                = "cognito-with-iam"
  schema              = <<EOF

type Outer {
	scalar: String
@aws_cognito_user_pools(cognito_groups: ["admin"])
	inner: Inner
@aws_cognito_user_pools(cognito_groups: ["admin"])
}

type Inner {
	inner_scalar: String
@aws_cognito_user_pools(cognito_groups: ["admin"])
}

type Query {
	query_scalar: String
@aws_cognito_user_pools(cognito_groups: ["admin"])
	outer: Outer
@aws_cognito_user_pools
}
EOF
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  user_pool_config {
    default_action = "ALLOW"
    user_pool_id   = aws_cognito_user_pool.pool.id
  }
  additional_authentication_provider {
    authentication_type = "AWS_IAM"
  }
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = "ALL"
  }
}

module "appsync_cognito_only" {
  source  = "./modules/appsync_resources"
  appsync = aws_appsync_graphql_api.appsync_cognito_only
}

module "appsync_cognito_with_iam" {
  source  = "./modules/appsync_resources"
  appsync = aws_appsync_graphql_api.appsync_cognito_with_iam
}

resource "aws_iam_role" "appsync_logs" {
  assume_role_policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [
		{
		"Effect": "Allow",
		"Principal": {
			"Service": "appsync.amazonaws.com"
		},
		"Action": "sts:AssumeRole"
		}
	]
}
POLICY
}
data "aws_iam_policy_document" "appsync_push_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role_policy" "appsync_logs" {
  role   = aws_iam_role.appsync_logs.id
  policy = data.aws_iam_policy_document.appsync_push_logs.json
}

# cognito
resource "aws_cognito_user_pool" "pool" {
  name = "test-${random_id.id.hex}"
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "client"

  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_group" "user" {
  name         = "user"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user" "cognito_user" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = "user"
  attributes = {
    email = "user@example.com"
  }
  password = "Password.1"
}

resource "aws_cognito_user_in_group" "cognito_user_in_group" {
  user_pool_id = aws_cognito_user_pool.pool.id
  group_name   = aws_cognito_user_group.user.name
  username     = aws_cognito_user.cognito_user.username
}

