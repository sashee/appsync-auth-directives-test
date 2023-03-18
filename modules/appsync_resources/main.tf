variable "appsync" {
}

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/appsync/apis/${var.appsync.id}"
  retention_in_days = 14
}

resource "aws_appsync_datasource" "ds" {
  api_id           = var.appsync.id
  name             = "none"
  type             = "NONE"
}

resource "aws_appsync_function" "Query_scalar_1" {
  api_id      = var.appsync.id
  data_source = aws_appsync_datasource.ds.name
  name        = "Query_scalar"
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
  code = <<EOF
import {util} from "@aws-appsync/utils";

export function request(ctx) {
	return {
		version : "2018-05-29",
		payload: "query_scalar"
	}
}

export function response(ctx) {
	if (ctx.error) {
		return util.error(ctx.error.message, ctx.error.type);
	}
	return ctx.result;
}
EOF
}

resource "aws_appsync_resolver" "Query_scalar" {
  api_id = var.appsync.id
  type   = "Query"
  field  = "query_scalar"

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
  code = <<EOF
export function request(ctx) {
	return {};
}

export function response(ctx) {
	return ctx.result;
}
EOF
  kind = "PIPELINE"
  pipeline_config {
    functions = [
      aws_appsync_function.Query_scalar_1.function_id,
    ]
  }
}

resource "aws_appsync_function" "Query_outer_1" {
  api_id      = var.appsync.id
  data_source = aws_appsync_datasource.ds.name
  name        = "Query_outer"
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
  code = <<EOF
import {util} from "@aws-appsync/utils";

export function request(ctx) {
	return {
		version : "2018-05-29",
		payload: {
			scalar: "outer_scalar",
			inner: {
				inner_scalar: "inner_scalar"
			}
		}
	}
}

export function response(ctx) {
	if (ctx.error) {
		return util.error(ctx.error.message, ctx.error.type);
	}
	return ctx.result;
}
EOF
}

resource "aws_appsync_resolver" "Query_outer" {
  api_id = var.appsync.id
  type   = "Query"
  field  = "outer"

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
  code = <<EOF
export function request(ctx) {
	return {};
}

export function response(ctx) {
	return ctx.result;
}
EOF
  kind = "PIPELINE"
  pipeline_config {
    functions = [
      aws_appsync_function.Query_outer_1.function_id,
    ]
  }
}

