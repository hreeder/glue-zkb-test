terraform {
  backend "s3" {
    bucket         = "hreeder-glue-zkb-test-state"
    key            = "ingest-sde.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "hreeder-glue-zkb-test-state-locks"
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "sde" {
  bucket = "hreeder-glue-zkb-test-sde"
}

resource "aws_s3_bucket_public_access_block" "sde" {
  bucket = aws_s3_bucket.sde.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_ecr_repository" "transformer" {
  name = "hreeder/glue-zkb-test/sde-transform"
}

module "transformer" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "hreeder-glue-zkb-test-sde-transformer"
  description   = "Transform SDE from YAML to JSON"

  publish        = true
  create_package = false
  image_uri      = "${data.aws_ecr_repository.transformer.repository_url}:latest"
  package_type   = "Image"
  architectures  = ["x86_64"]

  allowed_triggers = {
    s3 = {
      principal  = "s3.amazonaws.com"
      source_arn = aws_s3_bucket.sde.arn
    }
  }
}

resource "aws_s3_bucket_notification" "sde_transform" {
  bucket = aws_s3_bucket.sde.bucket

  lambda_function {
    lambda_function_arn = module.transformer.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".yaml"
  }

  lambda_function {
    lambda_function_arn = module.transformer.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".staticdata"
  }
}
