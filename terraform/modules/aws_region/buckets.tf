// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

resource "aws_s3_bucket" "lsc_storage" {
  bucket = "${var.eks_cluster_name}-lsc-storage-${local.short_uuid}"
}

resource "aws_s3_bucket_ownership_controls" "lsc_storage" {
  bucket = aws_s3_bucket.lsc_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "lsc_storage" {
  bucket = aws_s3_bucket.lsc_storage.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket" "code_storage" {
  bucket = "${var.eks_cluster_name}-code-storage-${local.short_uuid}"
}

resource "aws_s3_bucket_ownership_controls" "code_storage" {
  bucket = aws_s3_bucket.code_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "code_storage" {
  bucket = aws_s3_bucket.code_storage.id

  versioning_configuration {
    status = "Disabled"
  }
}

data "aws_iam_policy_document" "functions_origin_access_policy" {
  statement {
    sid    = "AccessFromFunctionsOrigin"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${aws_s3_bucket.code_storage.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::*:role/functions-origin-*"]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalOrgPaths"

      values = [
        "o-rgae2fihtd/r-jfxt/ou-jfxt-7ln5b5lm/ou-jfxt-8ez0kkal/ou-jfxt-3rxyhrql/", # New Org > Root > Environments > Production > Services
        "o-rgae2fihtd/r-jfxt/ou-jfxt-7ln5b5lm/ou-jfxt-kfqgreg7/ou-jfxt-vd4cwr3w/", # New Org > Root > Environments > Staging > Services
      ]
    }
  }

  statement {
    sid = "BucketOperations"
    actions = [
      "s3:ListBucket", # is a s3:GetObject returns a 404 the AWS SDK throws a PermissionDenied if this permission not granted
    ]
    resources = [ aws_s3_bucket.code_storage.arn ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::*:role/functions-origin-*"]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:PrincipalOrgPaths"

      values = [
        "o-rgae2fihtd/r-jfxt/ou-jfxt-7ln5b5lm/ou-jfxt-8ez0kkal/ou-jfxt-3rxyhrql/", # New Org > Root > Environments > Production > Services
        "o-rgae2fihtd/r-jfxt/ou-jfxt-7ln5b5lm/ou-jfxt-kfqgreg7/ou-jfxt-vd4cwr3w/", # New Org > Root > Environments > Staging > Services
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "code_storage" {
  bucket = aws_s3_bucket.code_storage.id
  policy = data.aws_iam_policy_document.functions_origin_access_policy.json
}