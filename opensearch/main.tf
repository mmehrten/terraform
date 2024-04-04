/*
*   Create an OpenSearch cluster and assocaited infrastructure.
*/
locals {
  base-name        = "${var.app-shorthand-name}.${var.region}"
  remote-base-name = "${var.app-shorthand-name}.${var.remote-region}"
}

module "opensearch" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  vpc-id               = var.vpc-id
  domain-name          = replace("${local.base-name}.${var.cluster-id}", ".", "-")
  master-password      = var.opensearch-master-password
  ultrawarm-node-count = var.ultrawarm-node-count
  source               = "../terraform-main/aws/modules/opensearch"
}

module "opensearch-remote" {
  count              = var.use-cross-region ? 1 : 0
  providers          = { aws = aws.remote }
  region             = var.remote-region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.remote-base-name
  partition          = var.partition

  vpc-id          = var.remote-vpc-id
  domain-name     = replace("${local.remote-base-name}.${var.cluster-id}", ".", "-")
  master-password = var.opensearch-master-password
  source          = "../terraform-main/aws/modules/opensearch"
}

data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = var.vpc-id == null ? [] : [var.vpc-id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = [false]
  }
}

module "cloudwatch-parse-lambda" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  name = "cloudwatch-firehose-processor-${var.cluster-id}"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "kinesis-firehose:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "kinesis:*",
          "Resource" : "*"
        }
      ]
  })
  file-path  = "./cloudwatch_kinesis_firehose.py"
  handler    = "cloudwatch_kinesis_firehose.lambda_handler"
  runtime    = "python3.9"
  vpc-id     = var.vpc-id
  subnet-ids = data.aws_subnets.main.ids
  source     = "../terraform-main/aws/modules/lambda"
  timeout    = 15
}

module "os-configure-lambda" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  name       = "opensearch-configurer-${var.cluster-id}"
  role-arn   = module.opensearch.iam_role_arn
  file-path  = "./opensearch_controller/"
  handler    = "opensearch.handler"
  runtime    = "python3.9"
  vpc-id     = var.vpc-id
  subnet-ids = data.aws_subnets.main.ids
  layer_arns = [
    "arn:${var.partition}:lambda:${var.region}:${var.account-id}:layer:opensearch-py:5",
    "arn:${var.partition}:lambda:${var.region}:${var.account-id}:layer:langchain:3",
    "arn:${var.partition}:lambda:${var.region}:${var.account-id}:layer:nltk:3",
    "arn:${var.partition}:lambda:${var.region}:${var.account-id}:layer:requests:8",
  ]
  environment = {
    OPENSEARCH_ENDPOINT = module.opensearch.endpoint
  }
  source      = "../terraform-main/aws/modules/lambda"
  timeout     = 60 * 15
  memory-size = 512
}

resource "aws_opensearch_outbound_connection" "main" {
  count            = var.use-cross-region ? 1 : 0
  connection_alias = "outbound_connection"
  connection_mode  = "DIRECT"
  local_domain_info {
    owner_id    = var.account-id
    region      = var.region
    domain_name = module.opensearch.domain_name
  }

  remote_domain_info {
    owner_id    = var.account-id
    region      = var.remote-region
    domain_name = module.opensearch-remote[0].domain_name
  }
}

resource "aws_opensearch_inbound_connection_accepter" "main" {
  provider      = aws.remote
  count         = var.use-cross-region ? 1 : 0
  connection_id = aws_opensearch_outbound_connection.main[0].id
}

module "s3-data" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  bucket-name = "${local.base-name}.s3.opensearch.snapshot"
  versioning  = false
  source      = "../terraform-main/aws/modules/s3"
}

resource "aws_iam_role_policy" "manager-snapshots" {
  name = "${var.app-shorthand-name}.iam.policy.opensearch.snapshot"
  role = aws_iam_role.cluster-manager.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:ListBucket"
          ],
          "Effect" : "Allow",
          "Resource" : [
            module.s3-data.outputs.arn
          ]
        },
        {
          "Action" : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "${module.s3-data.outputs.arn}/*"
          ]
        },
        {
          "Action" : [
            "kms:GenerateDataKey",
            "kms:Encrypt",
            "kms:Decrypt",
          ],
          "Effect" : "Allow",
          "Resource" : [
            module.s3-data.outputs.kms-arn
          ]
        }

      ]
  })
}

resource "aws_iam_role_policy" "manager-models" {
  name = "${var.app-shorthand-name}.iam.policy.opensearch.ml"
  role = aws_iam_role.cluster-manager.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "sagemaker:InvokeEndpointAsync",
            "sagemaker:InvokeEndpoint"
          ],
          "Effect" : "Allow",
          "Resource" : "*"
        }
      ]
  })
}

resource "aws_iam_role" "cluster-manager" {
  name                = "${var.app-shorthand-name}.iam.role.opensearch.manager"
  description         = "Role used to manage AWS service integrations (e.g. S3 snapshots, ML models, etc.)"
  managed_policy_arns = []
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : { "Service" : "es.amazonaws.com" },
          "Effect" : "Allow",
          "Condition" : {
            "StringEquals" : {
              "aws:SourceAccount" : "${var.account-id}"
            },
            "ArnLike" : {
              "aws:SourceArn" : module.opensearch.arn
            }
          }
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "lambda-pass-to-manager" {
  name = "${var.app-shorthand-name}.iam.policy.opensearch.admin-snap"
  role = module.os-configure-lambda.iam_role_id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "iam:PassRole",
          "Resource" : aws_iam_role.cluster-manager.arn
        }
      ]
    }
  )
}

resource "aws_lambda_invocation" "roles" {
  for_each = {
    "role_mapping_all_access" : {
      "type" : "role_mapping",
      "role_name" : "all_access",
      "body" : {
        "backend_roles" : [
          module.opensearch.iam_role_arn,
          module.os-configure-lambda.iam_role_arn,
          "arn:${var.partition}:iam::${var.account-id}:role/Admin"
        ]
        "users" : ["auth0|64bffaad9b3360ade9693c7c"]
      }
    }
    "role_mapping_security_manager" : {
      "type" : "role_mapping",
      "role_name" : "security_manager",
      "body" : {
        "backend_roles" : [
          module.opensearch.iam_role_arn,
          module.os-configure-lambda.iam_role_arn,
          "arn:${var.partition}:iam::${var.account-id}:role/Admin"
        ]
        "users" : ["auth0|64bffaad9b3360ade9693c7c"]
      }
    }
    "role_mapping_manage_snapshots" : {
      "type" : "role_mapping",
      "role_name" : "manage_snapshots",
      "body" : {
        "backend_roles" : [
          aws_iam_role.cluster-manager.arn,
        ]
      }
    }
    "role_mapping_ml_full_access" : {
      "type" : "role_mapping",
      "role_name" : "ml_full_access",
      "body" : {
        "backend_roles" : [
          aws_iam_role.cluster-manager.arn,
        ]
      }
    }
  }
  function_name = module.os-configure-lambda.function_name

  input = jsonencode(each.value)
}

resource "aws_lambda_invocation" "snaps" {
  depends_on = [aws_lambda_invocation.roles]
  for_each = {
    "snap" : {
      "type" : "snap",
      "method" : "PUT",
      "path" : "/_snapshot/${module.s3-data.outputs.name}",
      "body" : {
        "type" : "s3",
        "settings" : {
          "bucket" : module.s3-data.outputs.name,
          "region" : var.region,
          "role_arn" : aws_iam_role.cluster-manager.arn
        }
      }
    }
  }
  function_name = module.os-configure-lambda.function_name
  input         = jsonencode(each.value)
}

resource "aws_lambda_invocation" "ml-setup" {
  depends_on = [aws_lambda_invocation.roles]
  for_each = {
    "ml_settings" : {
      "type" : "ml",
      "method" : "PUT",
      "path" : "/_cluster/settings",
      "body" : {
        "persistent" : {
          "plugins.ml_commons.only_run_on_ml_node" : false,
          "plugins.ml_commons.model_auto_redeploy.enable" : true
          # Don't work in AWS Managed? Causes API to fail:
          # "plugins.ml_commons.agent_framework_enabled" : true,
          # "plugins.ml_commons.rag_pipeline_feature_enabled" : true,
          # "assistant.chat.enabled" : true,
          # "observability.query_assist.enabled" : true,
        }
      }
    }
    "local_sentence_model_group" : {
      "type" : "ml",
      "method" : "POST",
      "path" : "/_plugins/_ml/model_groups/_register",
      "body" : {
        "name" : "local_sentence_model_group",
        "description" : "A model group for local sentence models"
      }
    }
    "local_sparse_model_group" : {
      "type" : "ml",
      "method" : "POST",
      "path" : "/_plugins/_ml/model_groups/_register",
      "body" : {
        "name" : "local_sparse_model_group",
        "description" : "A model group for local sparse models"
      }
    }
  }
  function_name = module.os-configure-lambda.function_name

  input = jsonencode(each.value)
}

locals {
  models = {
    "huggingface/sentence-transformers/all-distilroberta-v1" : {
      "body" : {
        "name" : "huggingface/sentence-transformers/all-distilroberta-v1",
        "version" : "1.0.1",
        "model_group_id" : jsondecode(aws_lambda_invocation.ml-setup["local_sentence_model_group"].result).model_group_id,
        "model_format" : "TORCH_SCRIPT"
      },
      "dimension" : 768
    }
    "huggingface/sentence-transformers/multi-qa-MiniLM-L6-cos-v1" : {
      "body" : {
        "name" : "huggingface/sentence-transformers/multi-qa-MiniLM-L6-cos-v1",
        "version" : "1.0.1",
        "model_group_id" : jsondecode(aws_lambda_invocation.ml-setup["local_sentence_model_group"].result).model_group_id,
        "model_format" : "TORCH_SCRIPT"
      }
      "dimension" : 384
    }
    # "amazon/neural-sparse/opensearch-neural-sparse-encoding-v1" : {
    #   "body" : {
    #     "name" : "amazon/neural-sparse/opensearch-neural-sparse-encoding-v1",
    #     "version" : "1.0.1",
    #     "model_group_id" : jsondecode(aws_lambda_invocation.ml-setup["local_sparse_model_group"].result).model_group_id,
    #     "model_format" : "TORCH_SCRIPT"
    #   }
    # }
    # "amazon/neural-sparse/opensearch-neural-sparse-encoding-doc-v1" : {
    #   "body" : {
    #     "name" : "amazon/neural-sparse/opensearch-neural-sparse-encoding-doc-v1",
    #     "version" : "1.0.1",
    #     "model_group_id" : jsondecode(aws_lambda_invocation.ml-setup["local_sparse_model_group"].result).model_group_id,
    #     "model_format" : "TORCH_SCRIPT"
    #   }
    # }
    # "amazon/neural-sparse/opensearch-neural-sparse-tokenizer-v1" : {
    #   "body" : {
    #     "name" : "amazon/neural-sparse/opensearch-neural-sparse-tokenizer-v1",
    #     "version" : "1.0.1",
    #     "model_group_id" : jsondecode(aws_lambda_invocation.ml-setup["local_sparse_model_group"].result).model_group_id,
    #     "model_format" : "TORCH_SCRIPT"
    #   }
    # }
  }
}
resource "aws_lambda_invocation" "ml-models" {
  depends_on    = [aws_lambda_invocation.ml-setup]
  for_each      = local.models
  function_name = module.os-configure-lambda.function_name

  input = jsonencode({
    "type" : "ml",
    "method" : "POST",
    "path" : "/_plugins/_ml/models/_register",
    "body" : each.value.body,
  })
}

resource "time_sleep" "ml-models" {
  for_each        = aws_lambda_invocation.ml-models
  depends_on      = [aws_lambda_invocation.ml-models]
  create_duration = "5s"
}

resource "aws_lambda_invocation" "ml-tasks" {
  depends_on    = [time_sleep.ml-models]
  for_each      = aws_lambda_invocation.ml-models
  function_name = module.os-configure-lambda.function_name

  input = jsonencode({
    "type" : "ml",
    "method" : "GET",
    "path" : "/_plugins/_ml/tasks/${jsondecode(aws_lambda_invocation.ml-models[each.key].result).task_id}",
    "body" : {}
  })
}

resource "time_sleep" "ml-tasks" {
  for_each        = aws_lambda_invocation.ml-models
  depends_on      = [aws_lambda_invocation.ml-tasks]
  create_duration = "20s"
}

resource "aws_lambda_invocation" "ml-deploy" {
  depends_on    = [time_sleep.ml-tasks]
  for_each      = aws_lambda_invocation.ml-tasks
  function_name = module.os-configure-lambda.function_name

  input = jsonencode({
    "type" : "ml",
    "method" : "POST",
    "path" : "/_plugins/_ml/models/${jsondecode(aws_lambda_invocation.ml-tasks[each.key].result).model_id}/_deploy",
    "body" : {}
  })
}

resource "time_sleep" "ml-deploy" {
  for_each        = aws_lambda_invocation.ml-models
  depends_on      = [aws_lambda_invocation.ml-deploy]
  create_duration = "10s"
}

resource "aws_lambda_invocation" "ml-ingest-pipeline" {
  depends_on    = [time_sleep.ml-deploy]
  function_name = module.os-configure-lambda.function_name

  input = jsonencode({
    "type" : "ml",
    "method" : "PUT",
    "path" : "/_ingest/pipeline/nlp-pipeline",
    "body" : {
      "description" : "Ingest pipeline for NLP embedding models",
      "processors" : [
        for o in keys(aws_lambda_invocation.ml-deploy) :
        {
          "text_embedding" : {
            "model_id" : jsondecode(aws_lambda_invocation.ml-tasks[o].result).model_id,
            "field_map" : {
              "text" : "${split("/", o)[2]}_embedding"
            }
          }
        }
      ]
    }
  })
}

resource "aws_lambda_invocation" "ml-search-pipeline" {
  depends_on    = [time_sleep.ml-deploy]
  function_name = module.os-configure-lambda.function_name

  input = jsonencode({
    "type" : "ml",
    "method" : "PUT",
    "path" : "/_search/pipeline/default_model_pipeline",
    "body" : {
      "request_processors" : [
        {
          "neural_query_enricher" : {
            "neural_field_default_id" : {
              for o in keys(aws_lambda_invocation.ml-deploy) :
              "${split("/", o)[2]}_embedding" => jsondecode(aws_lambda_invocation.ml-tasks[o].result).model_id
            }
          }
        }
      ]
    }
  })
}

resource "aws_lambda_invocation" "ml-index" {
  depends_on    = [aws_lambda_invocation.ml-ingest-pipeline, aws_lambda_invocation.ml-search-pipeline]
  function_name = module.os-configure-lambda.function_name

  input = jsonencode({
    "type" : "ml",
    "method" : "PUT",
    "path" : "/demo-nlp-index",
    "body" : {
      "settings" : {
        "index.knn" : true,
        # "default_pipeline" : "nlp-pipeline",
        # "search.default_pipeline" : "default_model_pipeline"
      },
      "mappings" : {
        "properties" : merge(
          {
            "text" : {
              "type" : "text"
            }
            "upload_timestamp" : {
              "type" : "date"
              "format" : "strict_date_time||epoch_millis"
            }
            "processed_timestamp" : {
              "type" : "date"
              "format" : "strict_date_time||epoch_millis"
            }
          },
          {
            for model, data in local.models :
            "${split("/", model)[2]}_embedding" => {
              "type" : "knn_vector",
              "dimension" : data.dimension,
              "method" : {
                "engine" : lookup(data, "engine", "lucene"),
                "space_type" : lookup(data, "space", "l2"),
                "name" : lookup(data, "name", "hnsw"),
                "parameters" : lookup(data, "parameters", {})
              }
            }
          }
        )
      }
    }

  })
}


output "models-state" {
  value = aws_lambda_invocation.ml-models
}

output "tasks-state" {
  value = aws_lambda_invocation.ml-tasks
}

output "deploy-state" {
  value = aws_lambda_invocation.ml-deploy
}

output "ingest-pipeline-state" {
  value = aws_lambda_invocation.ml-ingest-pipeline
}

output "search-pipeline-state" {
  value = aws_lambda_invocation.ml-search-pipeline
}

module "s3-nlp-data" {
  region             = var.region
  account-id         = var.account-id
  app-shorthand-name = var.app-shorthand-name
  app-name           = var.app-name
  terraform-role     = var.terraform-role
  tags               = var.tags
  base-name          = local.base-name
  partition          = var.partition

  bucket-name = "${local.base-name}.s3.nlp"
  versioning  = false
  source      = "../terraform-main/aws/modules/s3"
}

resource "aws_iam_role_policy" "manager-nlp-data" {
  name = "${var.app-shorthand-name}.iam.policy.opensearch.nlp-data"
  role = module.os-configure-lambda.iam_role_id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:ListBucket"
          ],
          "Effect" : "Allow",
          "Resource" : [module.s3-nlp-data.outputs.arn]
        },
        {
          "Action" : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ],
          "Effect" : "Allow",
          "Resource" : ["${module.s3-nlp-data.outputs.arn}/*"]
        },
        {
          "Action" : [
            "kms:GenerateDataKey",
            "kms:Encrypt",
            "kms:Decrypt",
          ],
          "Effect" : "Allow",
          "Resource" : [module.s3-nlp-data.outputs.kms-arn]
        },
        {
          "Action" : [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
          ],
          "Effect" : "Allow",
          "Resource" : [aws_sqs_queue.queue.arn]
        }

      ]
  })
}

data "aws_iam_policy_document" "queue_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:${var.partition}:sqs:${var.region}:${var.account-id}:*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [module.s3-nlp-data.outputs.arn]
    }
  }
}
resource "aws_sqs_queue" "queue" {
  name                       = "${var.app-name}_s3-to-opensearch"
  policy                     = data.aws_iam_policy_document.queue_policy.json
  visibility_timeout_seconds = 300
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.s3-nlp-data.outputs.bucket

  queue {
    queue_arn = aws_sqs_queue.queue.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_event_source_mapping" "main" {
  event_source_arn                   = aws_sqs_queue.queue.arn
  function_name                      = module.os-configure-lambda.function_name
  batch_size                         = 10
  maximum_batching_window_in_seconds = 10
  scaling_config {
    maximum_concurrency = 10
  }
}
