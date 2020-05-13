# set backemd
terraform {
  backend "local" {
    path = "path-to-local-backend-folder/aws-staticwebsite-s3-route53/terraform.tfstate"
  }
}

# set provider
provider "aws" {
  region                  = var.aws_region
  profile                 = var.aws_iaac_profile
  shared_credentials_file = var.aws_iaac_credentials_file
}

# declare local variables
locals {
  log_bucket_name       = format("logs.%s.com", var.website_name)
  domain_bucket_name    = format("%s.com", var.website_name)
  subdomain_bucket_name = format("www.%s.com", var.website_name)
}

# declare template sources
data "template_file" "site-policy-file" {
  template = "${file("files/policy.json")}"
  vars = {
    resource_name = format("arn:aws:s3:::%s.com/*", var.website_name)
  }
}

# create the logs bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket        = local.log_bucket_name
  acl           = "log-delivery-write"
  force_destroy = true
  tags = {
    Name = local.log_bucket_name
    RG   = "learn"
  }
}

# create the logs folder in the logs bucket
resource "aws_s3_bucket_object" "logs" {
  bucket       = aws_s3_bucket.log_bucket.id
  key          = "logs/"
  content_type = "application/x-directory"
}

# create the domain s3 bucket for website
resource "aws_s3_bucket" "domain_bucket" {
  bucket        = local.domain_bucket_name
  force_destroy = true
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "logs/"
  }
  tags = {
    Name = local.domain_bucket_name
    RG   = "learn"
  }
}

# create the sub-domain s3 bucket for website
resource "aws_s3_bucket" "subdomain_bucket" {
  bucket        = local.subdomain_bucket_name
  force_destroy = true
  website {
    redirect_all_requests_to = format("http://%s.com", var.website_name)
  }
  tags = {
    Name = local.subdomain_bucket_name
    RG   = "learn"
  }
}

# upload static website content to domain bucket
resource "aws_s3_bucket_object" "site-content" {
  bucket       = aws_s3_bucket.domain_bucket.id
  content_type = "text/html"
  key          = "index.html"
  source       = "files/index.html"
  etag         = filemd5("files/index.html")
}

# apply policy to to domain bucket
resource "aws_s3_bucket_policy" "site-policy" {
  bucket = aws_s3_bucket.domain_bucket.id
  policy = data.template_file.site-policy-file.rendered
}
